#!/usr/bin/env ruby
# frozen_string_literal: true

# Script: link-local-shareFramework-package.rb
#
# Purpose:
#   For each configured project:
#     1. Remove specified xcframeworks from the target's Frameworks and Embed
#        Frameworks build phases, and remove their PBXFileReferences.
#     2. Add SharedFrameworks as a local Swift Package dependency in the project
#        and link the SharedFrameworks product to the target.
#
# Usage:
#   ruby scripts/link-local-shareFramework-package.rb
#
# Requirements:
#   gem install xcodeproj

require 'xcodeproj'
require 'pathname'

# ── Shared constants ───────────────────────────────────────────────────────────

SCRIPT_DIR = Pathname.new(__FILE__).dirname.realpath
REPO_ROOT  = SCRIPT_DIR.parent

SHARED_FRAMEWORKS_PRODUCT_NAME = 'SharedFrameworks'

# ── Project configurations ─────────────────────────────────────────────────────
#
# Each entry describes one .xcodeproj to modify:
#   :project_path           - path relative to REPO_ROOT
#   :target_name            - the target to modify inside that project
#   :frameworks_to_remove   - xcframework names to strip out
#   :shared_pkg_relative    - path to SharedFrameworks relative to the .xcodeproj

CONFIGURATIONS = [
  {
    project_path:         'UpstraUIKit/AmityUIKit4/AmityUIKit4.xcodeproj',
    target_name:          'AmityUIKit4',
    frameworks_to_remove: %w[
      AmityLiveKit.xcframework
      AmitySDK.xcframework
      LiveKitWebRTC.xcframework
    ],
    shared_pkg_relative:  '../SharedFrameworks'
  },
  {
    project_path:         'UpstraUIKit/SampleApp/SampleApp.xcodeproj',
    target_name:          'SampleApp',
    frameworks_to_remove: %w[
      AmitySDK.xcframework
      AmityLiveKit.xcframework
      LiveKitWebRTC.xcframework
    ],
    shared_pkg_relative:  '../SharedFrameworks'
  }
].freeze

# ── Helper: process one project ────────────────────────────────────────────────

def process_project(config)
  project_path   = REPO_ROOT / config[:project_path]
  target_name    = config[:target_name]
  to_remove      = config[:frameworks_to_remove]
  shared_pkg_rel = config[:shared_pkg_relative]

  puts "\n#{'=' * 70}"
  puts "Project : #{config[:project_path]}"
  puts "Target  : #{target_name}"
  puts '=' * 70

  abort "ERROR: Project not found at #{project_path}" unless project_path.exist?

  project = Xcodeproj::Project.open(project_path)

  target = project.targets.find { |t| t.name == target_name }
  abort "ERROR: Target '#{target_name}' not found in #{project_path}" unless target

  # ── Step 1: Remove xcframeworks ──────────────────────────────────────────────

  puts "\n── Step 1: Removing #{to_remove.count} framework(s) from '#{target_name}' ──"

  to_remove.each do |framework_name|
    puts "\n  [#{framework_name}]"

    # Remove from Frameworks build phase
    frameworks_phase = target.frameworks_build_phase
    build_files = frameworks_phase.files.select do |bf|
      bf.file_ref&.path&.end_with?(framework_name) ||
        bf.display_name == framework_name
    end

    if build_files.empty?
      puts '    [skip] Not found in Frameworks build phase (already removed?)'
    else
      build_files.each do |bf|
        puts "    Removing '#{bf.display_name}' from Frameworks build phase"
        frameworks_phase.remove_build_file(bf)
      end
    end

    # Remove from Embed Frameworks (CopyFiles) build phase
    embed_phases = target.copy_files_build_phases.select { |p| p.name == 'Embed Frameworks' }
    embed_phases.each do |phase|
      embed_files = phase.files.select do |bf|
        bf.file_ref&.path&.end_with?(framework_name) ||
          bf.display_name == framework_name
      end
      if embed_files.empty?
        puts '    [skip] Not found in Embed Frameworks phase'
      else
        embed_files.each do |bf|
          puts "    Removing '#{bf.display_name}' from Embed Frameworks phase"
          phase.remove_build_file(bf)
        end
      end
    end

    # Remove the PBXFileReference from the project
    file_refs = project.files.select { |f| f.path&.end_with?(framework_name) }
    if file_refs.empty?
      puts '    [skip] No PBXFileReference found'
    else
      file_refs.each do |ref|
        puts "    Removing PBXFileReference: #{ref.path}"
        ref.remove_from_project
      end
    end
  end

  # ── Step 2: Add SharedFrameworks local Swift Package ─────────────────────────

  puts "\n── Step 2: Adding SharedFrameworks as local Swift Package ──"

  existing_local_pkg = project.root_object.package_references.find do |pkg|
    pkg.isa == 'XCLocalSwiftPackageReference' &&
      pkg.relative_path == shared_pkg_rel
  end

  if existing_local_pkg
    puts '  [skip] XCLocalSwiftPackageReference for SharedFrameworks already exists'
    local_pkg_ref = existing_local_pkg
  else
    puts "  Adding XCLocalSwiftPackageReference → #{shared_pkg_rel}"
    local_pkg_ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
    local_pkg_ref.relative_path = shared_pkg_rel
    project.root_object.package_references << local_pkg_ref
  end

  existing_product_dep = target.package_product_dependencies.find do |dep|
    dep.product_name == SHARED_FRAMEWORKS_PRODUCT_NAME
  end

  if existing_product_dep
    puts "  [skip] Package product dependency '#{SHARED_FRAMEWORKS_PRODUCT_NAME}' already exists on target"
  else
    puts "  Adding package product dependency '#{SHARED_FRAMEWORKS_PRODUCT_NAME}' to target '#{target_name}'"
    product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    product_dep.product_name = SHARED_FRAMEWORKS_PRODUCT_NAME
    product_dep.package = local_pkg_ref
    target.package_product_dependencies << product_dep
  end

  # ── Save ─────────────────────────────────────────────────────────────────────

  puts "\n── Saving project ──"
  project.save
  puts "Done. Project saved to #{project_path}"
end

# ── Run all configurations ─────────────────────────────────────────────────────

CONFIGURATIONS.each { |config| process_project(config) }

puts "\n#{'=' * 70}"
puts 'All projects processed.'
puts '=' * 70
puts ''
puts 'Next steps:'
puts '  1. Open each .xcodeproj (or the workspace) in Xcode'
puts '  2. Xcode will resolve the SharedFrameworks local package automatically'
puts '  3. Verify each target links SharedFrameworks under'
puts '     Frameworks, Libraries, and Embedded Content'
