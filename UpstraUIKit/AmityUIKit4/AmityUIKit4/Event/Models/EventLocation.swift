//
//  EventLocation.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 15/10/25.
//

import SwiftUI
import AmitySDK

struct EventLocation: Equatable {
    var type: AmityEventType
    var platform: EventPlatform
    var address: String
    var externalPlatformUrl: String
    
    init(
        type: AmityEventType = .virtual,
        platform: EventPlatform = .livestream,
        address: String = "",
        externalPlatformUrl: String = ""
    ) {
        self.type = type
        self.platform = platform
        self.address = address
        self.externalPlatformUrl = externalPlatformUrl
    }
    
    func isValid() -> Bool {
        switch type {
        case .virtual:
            if platform == .livestream { return true }
            
            return !externalPlatformUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .inPerson:
            return !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

/// The platforms a Virtual event can be set up on, and which one the location
/// sheet opens on.
///
/// Livestream is the only platform Live owns — an external link is somebody
/// else's video call — so Live off takes that option and leaves the event
/// type alone. The module-availability spec (§10.2) gives the sheet
/// (`location_bottom_sheet`) to Events and names no id for the livestream
/// option, so the module is read directly, as Web's LocationForm reads it.
struct EventPlatformOptions {
    let platforms: [EventPlatform]

    init(isLiveEnabled: Bool = AmityUIKitConfigController.shared.isFeatureEnabled(AmityUIKitFeature.live)) {
        platforms = isLiveEnabled ? [.livestream, .external] : [.external]
    }

    /// What a new location starts on: livestream while it is offered.
    var defaultPlatform: EventPlatform { platforms[0] }

    /// The location the sheet opens on. A platform the sheet no longer offers
    /// opens on the default instead, rather than on a radio that is not drawn.
    /// Only the sheet's working copy moves: the saved location is replaced
    /// when the user saves, and not before.
    func opening(_ selection: EventLocation?) -> EventLocation {
        var location = selection ?? EventLocation(platform: defaultPlatform)
        if !platforms.contains(location.platform) {
            location.platform = defaultPlatform
        }
        return location
    }
}
