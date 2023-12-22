//
//  AmityStory.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/12/23.
//

import Foundation
import AmitySDK

public struct Story: Identifiable, Equatable {
    
    let storyObject: AmityStory
    
    public static func == (lhs: Story, rhs: Story) -> Bool {
        return lhs.id == rhs.id
    }
    
    public var id: String {
        return storyId
    }
    
    var storyId: String
    var creatorId: String
    var dataType: String
    var targetId: String
    var targetType: String
    var data: [String: Any]?
    var items: [AmityStoryItem]
    var expiresAt: Date
    var isDeleted: Bool
    var syncState: AmitySyncState
    var videoResolution: [AmityVideoResolution]
    
    let createdAt: Date
    let metadata: [String: Any]?
    
    
    var creatorName: String
    var creatorAvatarURLStr: String
    var imageURL: URL?
    var videoURLStr: String?
    
    init(story: AmityStory) {
        storyObject = story
        storyId = story.storyId
        creatorId = story.creatorId
        dataType = story.dataType
        targetId = story.targetId
        targetType = story.targetType
        data = story.data
        items = story.items
        expiresAt = story.expiresAt
        createdAt = story.createdAt
        metadata = story.metadata
        isDeleted = story.isDeleted
        syncState = story.syncState
        videoResolution = story.availableResolution()
        
        creatorName = story.creator?.displayName ?? ""
        creatorAvatarURLStr = story.creator?.getAvatarInfo()?.fileURL ?? ""
        if let url = story.getImageInfo()?.fileURL {
            imageURL = URL(string: url + "?size=large")
        }
        
        let resolutions = story.availableResolution()
        if resolutions.contains(.res_720p) {
            videoURLStr = story.getVideoInfo()?.getVideo(resolution: .res_720p)
        } else  {
            videoURLStr = story.getVideoInfo()?.fileURL
        }
    
    }
    
    
    func getStoryObject() -> AmityStory {
        return storyObject
    }
    
    
    func getPreviewData() -> [(key: String, value: String)] {
        return [
            ("Story Id:", storyId),
            ("Creator ID:", creatorId),
            ("Data Type:", dataType),
            ("Target Type:", targetType),
            ("Target Id:", targetId),
            ("MetaData", metadata?.description ?? ""),
            ("Created At:", "\(createdAt)"),
            ("Data:", data?.description ?? ""),
            ("Items:", "\(items)"),
            ("Expires At:", "\(expiresAt)"),
            ("Is Deleted:", "\(isDeleted)"),
            ("Sync State:", "\(syncState)"),
            ("Video Resolution:", "\(videoResolution)")
        ]
    }
}
