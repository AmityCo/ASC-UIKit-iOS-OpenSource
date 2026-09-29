//
//  AmityUIKitModuleAvailability.swift
//  AmityUIKit4
//

import Foundation

/// Whether a module is available in this app, and when it is not, why.
///
/// `available`, not `enabled`: a module is withheld by the network's plan, not
/// switched off by anyone at hand, and "enabled" invites the question *enabled
/// by whom*. The plan is the only source that can withhold a module — nothing
/// local can withhold or grant one (module-availability §3.1).
///
/// The reason matters because it sends a customer to different conversations.
/// A module that was never sold to the network is about that module; one held
/// off by a prerequisite is about a different one, and naming the wrong module
/// sends the customer to ask for something they already have (REQ-022).
public enum AmityUIKitModuleAvailability: Equatable {

    case available(feature: AmityUIKitFeature)

    /// The network's plan does not include this module, and core is enforcing.
    /// Reported ahead of any prerequisite: when a module is both ungranted and
    /// short of its prerequisites, the reason about itself is the one to give
    /// (REQ-010).
    case notGranted(feature: AmityUIKitFeature)

    /// The whole `requires` list, because any one entry would have satisfied it
    /// — naming a single module misdirects. Telling a Community-only customer
    /// that Comment needs Post hides that Story would also have done.
    ///
    /// Raw catalog keys, exactly as the catalog spells them, not
    /// `AmityUIKitFeature`: a prerequisite can be a key this build predates
    /// (`externalContent` today), and it is carried rather than dropped —
    /// filtering to the enum would hide the very prerequisite a customer is
    /// missing (REQ-023).
    case prerequisiteUnavailable(feature: AmityUIKitFeature,
                                 unsatisfied: [String])

    public var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }

    public var feature: AmityUIKitFeature {
        switch self {
        case .available(let feature),
             .notGranted(let feature),
             .prerequisiteUnavailable(let feature, _):
            return feature
        }
    }
}
