//
//  ModuleFlagsModel.swift
//  SampleApp
//
//  The Phase 1 modules: what the network grants, and what the UIKit's gate makes
//  of it. The network's plan is the only source that withholds a module
//  (module-availability §3.1), and nothing here can change it: the screen is
//  read-only.
//
//  Everything here goes through AmityUIKit4Manager, so the screen cannot show a
//  module as on that the UIKit will treat as off. The list, the requirements and
//  the verdicts all come from the UIKit; only the labels live here.
//

import Foundation
import AmityUIKit4
import AmitySDK

enum ModuleFlags {

    /// Reading order, coarse to fine: what sells alone, then what builds on it.
    ///
    /// No clip: it is part of Post, not a module, and follows Post alone.
    static let order: [String] = [
        "community", "chat", "live", "poll", "userRelationship", "pushNotification",
        "post", "story", "events", "feed", "comment", "reaction", "product", "ads",
        "discovery",
    ]

    private static let labels: [String: String] = [
        "community": "Community", "chat": "Chat", "live": "Live", "poll": "Poll",
        "userRelationship": "User Relationship", "pushNotification": "Push Notification",
        "post": "Post", "story": "Story", "events": "Events", "feed": "Feed",
        "comment": "Comment", "reaction": "Reaction", "product": "Product",
        "ads": "Ads", "discovery": "Discovery",
    ]

    private static let notes: [String: String] = [
        "feed": "feed surfaces, notification tray, For You",
        "discovery": "search, trending, recommendation",
        "pushNotification": "OS-level push settings",
        "post": "clip surfaces included",
    ]

    static func label(_ key: String) -> String { labels[key] ?? key }

    static func note(_ key: String) -> String? { notes[key] }

    /// "needs Community" / "needs one of Post or Story" — nil when it sells alone.
    static func requirementText(_ key: String) -> String? {
        guard let r = AmityUIKit4Manager.moduleRequirements[key] else { return nil }
        var parts: [String] = []
        if !r.all.isEmpty {
            parts.append("needs " + r.all.map(label).joined(separator: " and "))
        }
        if !r.any.isEmpty {
            parts.append("needs one of " + r.any.map(label).joined(separator: " or "))
        }
        return parts.isEmpty ? nil : parts.joined(separator: "; ")
    }

    // ---------------------------------------------------------------------
    // What the network says, and what the gate made of it.
    // ---------------------------------------------------------------------

    /// The row the SDK persisted from `GET /api/v3/network-settings/modules`, or
    /// nil before one has landed. Read per render — this screen is opened by
    /// hand; the UIKit's own gate never reads per query.
    private static var settings: AmityModuleSettings? {
        AmityUIKit4Manager.client.getModuleSettings()
    }

    /// The network's state in a sentence, and the grants under it.
    static var entitlementSummary: (String, String?) {
        guard let settings else {
            return ("No answer yet — this network has not returned module settings. "
                    + "Every module below is available, and nothing cascades.", nil)
        }
        // Count both sides over `kind: api` only. The grants carry every module
        // the network owns, `kind: setting` ones included — Console and
        // Dashboard capabilities with no UIKit surface — and counting those
        // against a denominator of api modules reads "Granted 18 of 15".
        let apiKeys = Set(settings.catalog.filter { $0.value.kind == .api }.keys)
        let granted = settings.modules.filter { $0.value && apiKeys.contains($0.key) }
            .keys.sorted().map(label)
        let api = apiKeys.count
        let mode: String
        switch settings.enforcement {
        case .enforce:
            mode = "Enforcing — a module the network did not grant is off here."
        case .shadow:
            mode = "Shadow — nothing is withheld. The backend records what enforcing would have done."
        case .off:
            mode = "Off — nothing is withheld. The grants below are recorded but not applied."
        }
        let counts: String
        if granted.isEmpty {
            counts = "Granted none of \(api)."
        } else if granted.count == api {
            counts = "Granted all \(api)."
        } else if settings.enforcement == .enforce {
            // Under enforce the withheld list is what a tester scans for, so the
            // grants stay a count and the list below carries the detail.
            counts = "Granted \(granted.count) of \(api)."
        } else {
            counts = "Granted \(granted.count) of \(api): \(granted.joined(separator: ", "))."
        }
        return (mode, counts)
    }

    /// The api modules this network withholds — empty unless it is enforcing.
    static var withheldByNetwork: [String] {
        guard let settings, settings.enforcement == .enforce else { return [] }
        return settings.catalog
            .filter { $0.value.kind == .api && settings.modules[$0.key] != true }
            .keys.sorted().map(label)
    }

    /// What the backend said about one module, whatever the gate made of it.
    static func networkValue(_ key: String) -> String {
        guard let settings else { return "no answer yet" }
        guard settings.catalog[key] != nil else {
            return "not in the catalog — the network is never asked about it"
        }
        let value: String
        switch settings.modules[key] {
        case true?: value = "granted"
        case false?: value = "not granted"
        case nil: value = "not in the response (counts as not granted)"
        }
        // Without this a tester files a bug against a shadow network.
        return settings.enforcement == .enforce ? value : "\(value) · not enforced"
    }

    /// Whether the UIKit resolves this module on — the gate's own answer.
    static func isAvailable(_ key: String) -> Bool {
        guard let feature = AmityUIKitFeature(rawValue: key) else { return true }
        return AmityUIKit4Manager.moduleAvailability(feature).isAvailable
    }

    /// Why a module is withheld: the gate's reason by name, then in the
    /// tester's words. Nil when it is available.
    static func reason(_ key: String) -> String? {
        guard let feature = AmityUIKitFeature(rawValue: key) else { return nil }
        switch AmityUIKit4Manager.moduleAvailability(feature) {
        case .available:
            return nil
        case .notGranted:
            return "notGranted — the network does not grant it"
        case .prerequisiteUnavailable(_, let unsatisfied):
            return "prerequisiteUnavailable [\(unsatisfied.joined(separator: ", "))] — "
                + unmetText(feature: feature, unsatisfied: unsatisfied)
        }
    }

    /// `unsatisfied` is raw catalog keys, unknown ones included, so a key
    /// this build has no label for still shows — as the catalog spells it.
    private static func unmetText(
        feature: AmityUIKitFeature,
        unsatisfied: [String]
    ) -> String {
        let names = unsatisfied.map(label)
        let requirement = AmityUIKit4Manager.moduleRequirements[feature.rawValue]
        let anyNames = requirement.map { $0.any.map { label($0) } } ?? []
        let isAnyOf = !anyNames.isEmpty && anyNames == names
        switch names.count {
        case 0: return "its requirements cannot be resolved"
        case 1: return "\(names[0]) is off"
        case 2 where isAnyOf: return "neither \(names[0]) nor \(names[1]) is on"
        case 2: return "\(names[0]) and \(names[1]) are off"
        default:
            return isAnyOf
                ? "none of \(names.joined(separator: ", ")) is on"
                : "\(names.dropLast().joined(separator: ", ")) and \(names.last!) are off"
        }
    }

}
