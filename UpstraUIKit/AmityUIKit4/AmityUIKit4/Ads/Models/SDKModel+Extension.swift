//
//  SDKModel+Extension.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/6/2567 BE.
//

import Foundation
import AmitySDK
import RealmSwift

extension AmityAdsSettings {
    
    func getAdFrequency(for placement: AmityAdPlacement) -> AmityAdFrequency? {
        switch placement {
        case .chat, .chatList:
            return nil
        case .feed:
            return self.frequency?.feed
        case .story:
            return self.frequency?.story
        case .comment:
            return self.frequency?.comment
        @unknown default:
            return nil
        }
    }
}

extension AmityAdFrequency {
    
    var isTypeTimeWindow: Bool {
        return self.type == "time-window"
    }
}

extension AmityAd {
    
    /// Constructing new unique id so that there is no error even if same ad gets repeated in the list.
    func createUniqueId(withContentId modelId: String) -> String {
        return self.adId + modelId
    }
}

extension AmityImageData {
    
    var largeFileURL: String {
        return fileURL + "?size=large"
    }
}
