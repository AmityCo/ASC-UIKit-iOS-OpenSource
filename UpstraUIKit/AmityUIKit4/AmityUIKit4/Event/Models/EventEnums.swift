//
//  EventEnums.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 15/10/25.
//

import SwiftUI
import AmitySDK

public enum AmityEventSetupPageMode {
    case create(targetId: String, targetName: String)
    case edit(event: AmityEvent)
    
    var pageTitle: String {
        switch self {
        case .create(_, let targetName):
            return targetName
        case .edit:
            return "Edit event"
        }
    }
}

extension AmityEventType {
    
    var title: String {
        switch self {
        case .virtual:
            return "Virtual"
        case .inPerson:
            return "In-person"
        @unknown default:
            return ""
        }
    }
}

enum EventPlatform: String {
    case livestream = "Live stream"
    case external = "External platform"
}
