//
//  ASCMentionManager.swift
//  AmityUIKit
//
//  Created by Nishan on 8/7/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

struct MentionAttribute {
    let attributes: [NSAttributedString.Key: Any]
    let range: NSRange
    let userId: String
}

public enum AmityMentionManagerType {
    case post(communityId: String?)
    case comment(communityId: String?)
    case message(channelId: String?)
}

public struct AmityMentionUserModel {
    
    let userId: String
    let displayName: String
    let avatarURL: String
    let isGlobalBan: Bool
    let isChannelMention: Bool
    
    // We don't have mention in chat in uikit v3.
    var type: AmityMessageMentionType {
        return isChannelMention ? .channel : .user
    }
    
    init(user: AmityUser) {
        self.userId = user.userId
        self.displayName = user.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString
        self.avatarURL = user.getAvatarInfo()?.fileURL ?? ""
        self.isGlobalBan = user.isGlobalBanned
        self.isChannelMention = false
    }
    
    internal init(userId: String, displayName: String, avatarURL: String, isGlobalBan: Bool, isChannelMention: Bool) {
        self.userId = userId
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.isGlobalBan = isGlobalBan
        self.isChannelMention = isChannelMention
    }
    
    static let channelMention = AmityMentionUserModel(userId: "", displayName: "All", avatarURL: "", isGlobalBan: false, isChannelMention: true)
}

public protocol ASCMentionManagerDelegate: AnyObject {
    func didUpdateMentionUsers(users: [AmityMentionUserModel])
    func didCreateAttributedString(attributedString: NSAttributedString)
    func didReachMaxMentionLimit()
    func didReachMaxCharacterCountLimit()
}

/// ASCMentionManager works in combination with:
///
/// - MentionEditor: Handle editing of mention text in textview
/// - MentionListProvider: Handle query of mention users & return it.
public final class ASCMentionManager: MentionTextEditorDelegate {
    
    public static let maximumCharacterCountForPost = 50000
    public static let maximumMentionsCount = 30
    
    // Properties
    private let type: AmityMentionManagerType
    
    // Default Attributes used to highlight mentions
    public var highlightAttributes: [NSAttributedString.Key: Any] = [.font: AmityFontSet.bodyBold, .foregroundColor: AmityColorSet.primary] {
        didSet {
            mentionEditor.highlightAttributes = highlightAttributes
        }
    }
    
    // Default Attributes used for text while typing
    public var typingAttributes: [NSAttributedString.Key: Any] = [.font: AmityFontSet.body, .foregroundColor: AmityColorSet.base] {
        didSet {
            mentionEditor.typingAttributes = typingAttributes
        }
    }
    
    public weak var delegate: ASCMentionManagerDelegate?

    // Provides list of users for mention
    public let mentionProvider: MentionListProvider
    let mentionEditor: MentionTextEditor
    
    public init(withType type: AmityMentionManagerType) {
        self.mentionEditor = MentionTextEditor()
        self.type = type
        self.mentionProvider = MentionListProvider(type: type)
        self.mentionProvider.didGetMentionList = { [weak self] users in
            guard let self else { return }
            
            switch mentionEditor.mentionState {
            case .search:
                self.delegate?.didUpdateMentionUsers(users: users)
            case .idle:
                break
            }
        }
        self.mentionEditor.delegate = self
    }
    
    // MARK: Delegate MentionTextEditorDelegate
    
    func didChangeMentionState(state: MentionTextEditor.MentionState) {
        switch state {
        case .idle:
            mentionProvider.mentionList = []
            delegate?.didUpdateMentionUsers(users: [])
        case .search(let key):
            mentionProvider.searchUser(text: key)
        }
    }
    
    func didUpdateAttributedText(text: NSAttributedString) {
        delegate?.didCreateAttributedString(attributedString: text)
        
        if text.string.count > ASCMentionManager.maximumCharacterCountForPost {
            delegate?.didReachMaxCharacterCountLimit()
        }
    }
    
    public func changeSelection(_ textInput: UITextInput) {
        mentionEditor.changeSelection(textInput)
    }
    
    public func shouldChangeTextIn(_ textInput: UITextInput, inRange range: NSRange, replacementText: String, currentText text: String) -> Bool {
        return mentionEditor.processUserInput(in: textInput, range: range, replacementText: replacementText, currentText: text)
    }
    
    public func addMention(from textInput: UITextInput, in text: String, at indexPath: IndexPath) {
        if mentionEditor.mentions.count >= ASCMentionManager.maximumMentionsCount {
            delegate?.didReachMaxMentionLimit()
            return
        }
        
        guard indexPath.row < mentionProvider.mentionList.count else { return }
        let member = mentionProvider.mentionList[indexPath.row]
        
        mentionEditor.addMention(member: member, textInput: textInput, currentText: text)
    }
    
    public func isMentionWithinLimit(limit: Int) -> Bool {
        return mentionEditor.mentions.count < limit
    }
    
    public func addMention(from textInput: UITextInput, in text: String, member: AmityMentionUserModel) {
        if mentionEditor.mentions.count >= ASCMentionManager.maximumMentionsCount {
            delegate?.didReachMaxMentionLimit()
            return
        }
        
        mentionEditor.addMention(member: member, textInput: textInput, currentText: text)
    }

    public func setMentions(metadata: [String: Any], inText text: String) {
        self.mentionEditor.setMentions(metadata: metadata, inText: text)
    }
    
    public func getMetadata(shift: Int = 0) -> [String: Any]? {
        if mentionEditor.mentions.isEmpty {
            return nil
        }
        
        let finalMentions = mentionEditor.mentions
        
        if shift != 0 {
            for i in 0..<mentionEditor.mentions.count {
                finalMentions[i].index += shift
            }
        }
                
        return AmityMentionMapper.metadata(from: finalMentions)
    }
    
    public func getMentionees() -> AmityMentioneesBuilder? {
        if mentionEditor.mentions.isEmpty {
            return nil
        }
        
        let mentionees: AmityMentioneesBuilder = AmityMentioneesBuilder()
        
        let userIds = mentionEditor.mentions.filter{ $0.type == .user }.compactMap { $0.userId }
        if !userIds.isEmpty {
            mentionees.mentionUsers(userIds: userIds)
        }
        
        switch type {
        case .message:
            if mentionEditor.mentions.contains(where: { $0.type == .channel }) {
                mentionees.mentionChannel()
            }
        default:
            break
        }
        
        return mentionees
    }

    // Reset everything to state before mention.
    public func resetState() {
        mentionEditor.reset()
        mentionProvider.reset()
    }
}
