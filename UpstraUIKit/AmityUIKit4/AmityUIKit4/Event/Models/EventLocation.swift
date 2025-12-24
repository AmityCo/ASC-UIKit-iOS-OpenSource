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
