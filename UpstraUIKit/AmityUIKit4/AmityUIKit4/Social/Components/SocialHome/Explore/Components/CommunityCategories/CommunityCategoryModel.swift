//
//  CommunityCategoryModel.swift
//  AmityUIKit4
//
//  Created by Nishan on 28/8/2567 BE.
//

import SwiftUI
import AmitySDK

struct CommunityCategoryModel: Identifiable {
    
    let id: String
    let name: String
    let avatar: AmityImageData?
    let avatarURL: URL?
    
    init(model: AmityCommunityCategory) {
        self.id = model.categoryId
        self.name = model.name
        self.avatar = model.avatar
        self.avatarURL = URL(string: model.avatar?.fileURL ?? "")
    }
}
