#!/usr/bin/env ruby
# frozen_string_literal: true

# Script: link_shared_frameworks.rb
#
# Purpose:
#   1. Remove xcframeworks listed in FRAMEWORKS_TO_REMOVE from the SampleApp target's
#      Frameworks and Embed Frameworks build phases, and remove their PBXFileReferences.
#   2. Add SharedFrameworks as a local Swift Package dependency in SampleApp.xcodeproj
#      and link the SharedFrameworks product to the SampleApp target.
#
# Usage:
#   ruby scripts/link_shared_frameworks.rb
#
# Requirements:
#   gem install xcodeproj

require 'xcodeproj'
require 'pathname'

# ── Paths ──────────────────────────────────────────────────────────────────────

SCRIPT_DIR   = Pathname.new(__FILE__).dirname.realpath
REPO_ROOT    = SCRIPT_DIR.parent
PROJECT_PATH = REPO_ROOT / 'UpstraUIKit' / 'SampleApp' / 'SampleApp.xcodeproj'
# Path to SharedFrameworks relative to the .xcodeproj directory
SHARED_FRAMEWORKS_RELATIVE_PATH = '../SharedFrameworks'
SHARED_FRAMEWORKS_PRODUCT_NAME  = 'SharedFrameworks'
TARGET_NAME          = 'SampleApp'
FRAMEWORKS_TO_REMOVE = %w[
  AmitySDK.xcframework
  AmityLiveVideoBroadcastKit.xcframework
  AmityVideoPlayerKit.xcframework
  MobileVLCKit.xcframework
  AmityLiveKit.xcframework
  LiveKitWebRTC.xcframework
].freeze

# ── Sanity checks ─────────────────────────────────────────────────────────────

abort "ERROR: Project not found at #{PROJECT_PATH}" unless PROJECT_PATH.exist?

puts "Opening project: #{PROJECT_PATH}"
project = Xcodeproj::Project.open(PROJECT_PATH)

# ── Locate SampleApp target ───────────────────────────────────────────────────

target = project.targets.find { |t| t.name == TARGET_NAME }
abort "ERROR: Target '#{TARGET_NAME}' not found in project." unless target

puts "Found target: #{target.name}"

# ── Step 1: Remove xcframeworks from SampleApp target ─────────────────────────

puts "\n── Step 1: Removing #{FRAMEWORKS_TO_REMOVE.count} framework(s) from #{TARGET_NAME} ──"

FRAMEWORKS_TO_REMOVE.each do |framework_name|
  puts "\n  [#{framework_name}]"

  # Remove from Frameworks build phase
  frameworks_phase = target.frameworks_build_phase
  build_files = frameworks_phase.files.select do |bf|
    bf.file_ref&.path&.end_with?(framework_name) ||
      bf.display_name == framework_name
  end

  if build_files.empty?
    puts "    [skip] Not found in Frameworks build phase (already removed?)"
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
      puts "    [skip] Not found in Embed Frameworks phase"
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
    puts "    [skip] No PBXFileReference found"
  else
    file_refs.each do |ref|
      puts "    Removing PBXFileReference: #{ref.path}"
      ref.remove_from_project
    end
  end
end

# ── Step 2: Add SharedFrameworks as a local Swift Package dependency ───────────

puts "\n── Step 2: Adding SharedFrameworks as local Swift Package ──"

# Check if a local package reference to SharedFrameworks already exists
existing_local_pkg = project.root_object.package_references.find do |pkg|
  pkg.isa == 'XCLocalSwiftPackageReference' &&
    pkg.relative_path == SHARED_FRAMEWORKS_RELATIVE_PATH
end

if existing_local_pkg
  puts "  [skip] XCLocalSwiftPackageReference for SharedFrameworks already exists"
  local_pkg_ref = existing_local_pkg
else
  puts "  Adding XCLocalSwiftPackageReference → #{SHARED_FRAMEWORKS_RELATIVE_PATH}"
  local_pkg_ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
  local_pkg_ref.relative_path = SHARED_FRAMEWORKS_RELATIVE_PATH
  project.root_object.package_references << local_pkg_ref
end

# Check if product dependency is already added to the target
existing_product_dep = target.package_product_dependencies.find do |dep|
  dep.product_name == SHARED_FRAMEWORKS_PRODUCT_NAME
end

if existing_product_dep
  puts "  [skip] Package product dependency '#{SHARED_FRAMEWORKS_PRODUCT_NAME}' already exists on target"
else
  puts "  Adding package product dependency '#{SHARED_FRAMEWORKS_PRODUCT_NAME}' to target '#{TARGET_NAME}'"
  product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  product_dep.product_name = SHARED_FRAMEWORKS_PRODUCT_NAME
  product_dep.package = local_pkg_ref
  target.package_product_dependencies << product_dep
end

# ── Save ──────────────────────────────────────────────────────────────────────

puts "\n── Saving project ──"
project.save
puts "Done. Project saved to #{PROJECT_PATH}"
puts ""
puts "Next steps:"
puts "  1. Open SampleApp.xcodeproj in Xcode"
puts "  2. Xcode will resolve the SharedFrameworks local package automatically"
puts "  3. Verify the SampleApp target links SharedFrameworks under Frameworks, Libraries, and Embedded Content"
