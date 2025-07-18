//
//  AmityReactionBar.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/17/25.
//

import SwiftUI
import AmitySDK

public struct AmityReactionBar: AmityComponentView {
    
    public var pageId: PageId?
    public var id: ComponentId {
        .reactionBar
    }
    
    public let targetType: String
    public let targetId: String
    
    private struct ReactionItem: Hashable {
        let icon: ImageResource
        let name: String
    }
    
    private let reactions: [AmityLiveReactionModel]
    
    private let reactionManager = ReactionManager()
    private var onReactionTap: ((AmityLiveReactionModel) -> Void)?
        
    public init(targetType: String, targetId: String, streamId: String, pageId: PageId? = nil, onReactionTap: ((AmityLiveReactionModel) -> Void)? = nil) {
        self.targetType = targetType
        self.targetId = targetId
        self.pageId = pageId
        self.onReactionTap = onReactionTap
        
        let targetType = AmityLiveReactionReferenceType(rawValue: targetType) ?? .post
        let reactionsDict = AmityUIKitConfigController.shared.config["reactions"] as? [[String: String]] ?? [[:]]
        var reactionsFromConfig: [AmityLiveReactionModel] = []
        reactionsDict.forEach { item in
            let name = item["name"] ?? ""
            let icon = ImageResource(name: item["image"] ?? "", bundle: AmityUIKit4Manager.bundle)
            
            let item = AmityLiveReactionModel(reactionName: name, referenceId: targetId, referenceType: targetType, streamId: streamId, icon: icon)
            reactionsFromConfig.append(item)
        }
        
        self.reactions = reactionsFromConfig
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            ForEach(reactions, id: \.reactionName) { reaction in
                Image(reaction.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .onTapGesture {
                        ImpactFeedbackGenerator.impactFeedback(style: .medium)
                        onReactionTap?(reaction)
                    }
            }
        }
        .padding(.all, 12)
        .background(Color.white.opacity(0.4))
        .cornerRadius(999)
    }
}
    
