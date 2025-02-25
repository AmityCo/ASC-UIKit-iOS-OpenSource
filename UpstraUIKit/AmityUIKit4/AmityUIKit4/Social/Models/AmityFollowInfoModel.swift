//
//  AmityFollowInfoModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/18/24.
//

import Foundation
import AmitySDK

struct AmityFollowInfoModel {
    let status: AmityFollowStatus?
    let followerCount: Int
    let followingCount: Int
    let pendingCount: Int?
    
    init(_ followInfo: AmityMyFollowInfo) {
        status = nil
        followerCount = Int(followInfo.followersCount)
        followingCount = Int(followInfo.followingCount)
        pendingCount = Int(followInfo.pendingCount)
    }
    
    init(_ followInfo: AmityUserFollowInfo) {
        status = followInfo.status
        followerCount = Int(followInfo.followersCount)
        followingCount = Int(followInfo.followingCount)
        pendingCount = nil
    }
}
