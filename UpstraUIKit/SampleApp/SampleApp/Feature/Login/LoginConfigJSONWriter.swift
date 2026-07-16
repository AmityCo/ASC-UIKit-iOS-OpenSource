//
//  LoginConfigJSONWriter.swift
//  SampleApp
//
//  Builds a runtime AmityUIKit config JSON from the bundled `AmityUIKitConfig.json`,
//  layering the user's Local Custom toggle values on top. Writes the merged file to
//  the app's Caches directory and returns the URL — `AmityUIKit4Manager.setConfigFile(_:)`
//  consumes the resulting path.
//
//  The framework's `AmityUIKitConfigController` is internal: there is no public runtime
//  setter for `preferred_theme`, `excludes`, or `feature_flags`. Rewriting the JSON +
//  pointing `setConfigFile` at it is the only public seam.
//

import Foundation

enum LoginConfigJSONWriter {

    private static let runtimeFileName = "AmityUIKitConfig.runtime.json"

    /// Element-level excludes used by Local Custom toggles. Wildcards `*/*/<element>` apply
    /// the exclude regardless of which page or component hosts the element.
    private enum ExcludeID {
        static let exploreButton = "*/*/explore_button"
        static let createCommunityButton = "*/*/create_community_button"
    }

    /// Loads the bundled config, applies the store's toggles, writes the result to Caches.
    /// Returns the URL of the written file, or `nil` if the bundled config is missing or
    /// the write fails — callers should fall back to the bundle path in that case.
    static func writeRuntimeConfig(from store: LoginConfigStore) -> URL? {
        guard let bundledURL = Bundle.main.url(forResource: "AmityUIKitConfig", withExtension: "json"),
              let data = try? Data(contentsOf: bundledURL),
              var config = (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)) as? [String: Any]
        else {
            return nil
        }

        config = applyToggles(to: config, store: store)

        guard let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let outputURL = cachesDir.appendingPathComponent(runtimeFileName)
        do {
            let outputData = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted])
            try outputData.write(to: outputURL, options: .atomic)
            return outputURL
        } catch {
            print("[LoginConfigJSONWriter] Failed to write runtime config: \(error)")
            return nil
        }
    }

    private static func applyToggles(to config: [String: Any], store: LoginConfigStore) -> [String: Any] {
        var config = config
        let toggles = store.config

        // preferred_theme: "default" | "light" | "dark"
        config["preferred_theme"] = toggles.theme.rawValue

        // feature_flags.post.clip.can_view_tab: "all" (visitor can view) | "signed_in_user_only"
        var featureFlags = (config["feature_flags"] as? [String: Any]) ?? [:]
        var post = (featureFlags["post"] as? [String: Any]) ?? [:]
        var clip = (post["clip"] as? [String: Any]) ?? [:]
        clip["can_view_tab"] = toggles.visitorCanViewClip ? "all" : "signed_in_user_only"
        post["clip"] = clip
        featureFlags["post"] = post
        config["feature_flags"] = featureFlags

        // excludes[]: dedupe via Set, then sort for stable diffs.
        var excludes = Set((config["excludes"] as? [String]) ?? [])
        toggle(ExcludeID.exploreButton, in: &excludes, isExcluded: toggles.hideExplore)
        toggle(ExcludeID.createCommunityButton, in: &excludes, isExcluded: !toggles.socialCommunityCreationButtonVisible)
        config["excludes"] = excludes.sorted()

        return config
    }

    private static func toggle(_ id: String, in excludes: inout Set<String>, isExcluded: Bool) {
        if isExcluded {
            excludes.insert(id)
        } else {
            excludes.remove(id)
        }
    }
}
