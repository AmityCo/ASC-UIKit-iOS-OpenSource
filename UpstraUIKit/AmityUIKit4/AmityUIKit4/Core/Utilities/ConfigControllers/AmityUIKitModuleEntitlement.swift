//
//  AmityUIKitModuleEntitlement.swift
//  AmityUIKit4
//

import Foundation
import AmitySDK

/// What the network was granted, in the only shape the gate needs.
///
/// Not a public type and not a mirror of the SDK's `AmityModuleSettings`: it
/// holds the three questions the snapshot asks — is enforcement on, is this
/// module granted, and what does the catalog say this module requires — so the
/// SDK model reaches the gate through one conversion instead of being read in
/// several places.
struct AmityUIKitModuleEntitlement {

    struct CatalogEntry {
        /// **Any one** entry satisfies it. The catalog's field is named
        /// `requires` and means any, where `features.json`'s `requires` means
        /// all — mapping the two by name would invert five rules.
        let requires: [String]
    }

    /// `off` and `shadow` both record the grants and withhold nothing: shadow is
    /// a dry run that core logs server-side. Only `enforce` withholds, so the
    /// mode collapses to this one question at the boundary.
    let isEnforcing: Bool

    /// Partial by design — a key that is absent was not granted.
    let granted: [String: Bool]

    /// The `api` modules the catalog carries, granted or not. A key absent from
    /// here is not an entitlement at all: the network is never asked to grant
    /// it, so an absent grant says nothing about it, and it has no rules.
    ///
    /// `kind: setting` entries are left out at the boundary (see the init
    /// below): they are Console and Dashboard capabilities with no UIKit
    /// surface, and the gate ignores them — as a module and as a prerequisite.
    let catalog: [String: CatalogEntry]

    /// Is this module granted, given what the network is under? The leaf
    /// predicate only — the prerequisite chain is walked by the snapshot, over
    /// the resolved answer, so a module that is granted but held off by its own
    /// prerequisite cannot satisfy a dependent either (REQ-011).
    func isGranted(_ key: String) -> Bool {
        guard isEnforcing else { return true }
        guard catalog[key] != nil else { return true }
        return granted[key] == true
    }
}

extension AmityUIKitModuleEntitlement {

    /// The one conversion from the SDK's row. Taking the parts rather than an
    /// `AmityModuleSettings` keeps it testable: the SDK type has no public
    /// initialiser, and the `kind: setting` filter is exactly the kind of rule
    /// a test must reach.
    ///
    /// Only `enforce` withholds; `off` and `shadow` collapse to not enforcing.
    /// A `setting` entry is dropped here rather than skipped at each read, so
    /// nothing downstream can walk into one: a catalog rule that named a
    /// setting would otherwise withhold a UIKit module over a Console
    /// capability. `unknown` kinds stay — the gate cannot tell them from a
    /// module a newer core sells, and a key this build's enum does not have is
    /// already ignored as a module in its own right.
    init(enforcement: AmityModuleEnforcementMode,
         granted: [String: Bool],
         catalog: [String: (kind: AmityModuleKind, requires: [String])]) {
        self.init(
            isEnforcing: enforcement == .enforce,
            granted: granted,
            catalog: catalog
                .filter { $0.value.kind != .setting }
                .mapValues { CatalogEntry(requires: $0.requires) })
    }
}
