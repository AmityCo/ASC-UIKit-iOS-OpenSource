//
//  StoryTarget.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/12/23.
//

import Foundation
import AmitySDK
import UIKit

public class StoryTarget: ObservableObject, Identifiable {
    public var id: String {
        UUID().uuidString
    }
    
    var targetName: String
    var isVerifiedTarget: Bool
    var placeholderImage: UIImage?
    @Published var stories: AmityCollection<AmityStory>
    @Published public var hasUnseen: Bool
    
    public init(targetName: String, isVerifiedTarget: Bool, placeholderImage: UIImage?, stories: AmityCollection<AmityStory>, hasUnseen: Bool) {
        self.targetName = targetName
        self.isVerifiedTarget = isVerifiedTarget
        self.placeholderImage = placeholderImage
        self.stories = stories
        self.hasUnseen = hasUnseen
    }
    
}
