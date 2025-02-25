//
//  AmityStoryCommentSettingsItem.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 11/3/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit

enum AmityStoryCommentSettingsItem: String {
    case allowComment
    
    var identifier: String {
        return String(describing: self)
    }
    
    var title: String {
        switch self {
        case .allowComment:
            return AmityLocalizedStringSet.StoryCommentSettings.itemTitleStoryComment.localizedString
        }
    }
    
    var description: String? {
        switch self {
        case .allowComment:
            return AmityLocalizedStringSet.StoryCommentSettings.itemDescStoryComment.localizedString
        }
    }
    
    var icon: UIImage? {
        return nil
    }
}
