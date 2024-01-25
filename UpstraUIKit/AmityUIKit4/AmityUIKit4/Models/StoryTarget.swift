//
//  StoryTarget.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/12/23.
//

import UIKit
import AmitySDK

public class StoryTarget: ObservableObject, Identifiable {
    public var id: String {
        UUID().uuidString
    }
    
    var targetId: String
    var targetName: String
    var isVerifiedTarget: Bool
    var avatar: UIImage?
    @Published var stories: AmityCollection<AmityStory>
    @Published var storyCount: Int = 0
    @Published var hasUnseenStory: Bool = false
    @Published var hasFailedStory: Bool = false
    @Published var hasSyncingStory: Bool = false
    
    public init(targetId: String, targetName: String, isVerifiedTarget: Bool, avatar: UIImage?, stories: AmityCollection<AmityStory>) {
        self.targetId = targetId
        self.targetName = targetName
        self.isVerifiedTarget = isVerifiedTarget
        self.avatar = avatar
        self.stories = stories
    }
    
}
