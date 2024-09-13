//
//  AmityCommunityCategoryModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/8/24.
//

import Foundation
import AmitySDK

/// Amity Community Category
public struct AmityCommunityCategoryModel: Hashable {
    public let name: String
    let avatarURL: String
    public let categoryId: String
    
    init(object: AmityCommunityCategory) {
        self.name = object.name
        self.avatarURL = object.avatar?.fileURL ?? ""
        self.categoryId = object.categoryId
    }
    
    init(id: String, name: String) {
        self.categoryId = id
        self.name = name
        self.avatarURL = ""
    }
}
