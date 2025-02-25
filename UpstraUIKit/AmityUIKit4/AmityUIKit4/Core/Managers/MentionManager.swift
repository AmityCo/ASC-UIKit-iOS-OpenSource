//
//  MentionManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/16/24.
//

import UIKit
import AmitySDK

struct MentionAttribute {
    let attributes: [NSAttributedString.Key: Any]
    let range: NSRange
    let userId: String
}

public class MentionData {
    var metadata: [String: Any]?
    var mentionee: AmityMentioneesBuilder?
}

public struct AmityMentionUserModel {
    
    let userId: String
    let displayName: String
    let avatarURL: String
    let isGlobalBan: Bool
    let isChannelMention: Bool
    let isBrand: Bool
    
    var type: AmityMessageMentionType {
        return isChannelMention ? .channel : .user
    }
    
    init(user: AmityUser) {
        self.userId = user.userId
        self.displayName = user.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString
        self.avatarURL = user.getAvatarInfo()?.fileURL ?? ""
        self.isGlobalBan = user.isGlobalBanned
        self.isChannelMention = false
        self.isBrand = user.isBrand
    }
    
    internal init(userId: String, displayName: String, avatarURL: String, isGlobalBan: Bool, isChannelMention: Bool) {
        self.userId = userId
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.isGlobalBan = isGlobalBan
        self.isChannelMention = isChannelMention
        self.isBrand = false
    }
    
    static let channelMention = AmityMentionUserModel(userId: "", displayName: "All", avatarURL: AmityIcon.Chat.mentionAll.rawValue, isGlobalBan: false, isChannelMention: true)
}

public protocol MentionManagerDelegate: AnyObject {
    
    func didUpdateMentionUsers(users: [AmityMentionUserModel])
    func didCreateAttributedString(attributedString: NSAttributedString)
}

public enum MentionManagerType {
    case post(communityId: String?)
    case comment(communityId: String?)
    case message(subChannelId: String?)
}

final public class MentionManager: MentionTextEditorDelegate {
    
    public static let maximumCharacterCountForPost = 50000
    public static let maximumMentionsCount = 30
    
    // Properties
    private let type: MentionManagerType
    
    // Default Attributes used to highlight mentions
    var highlightAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 15, weight: .bold), .foregroundColor: UIColor.systemBlue] {
        didSet {
            mentionEditor.highlightAttributes = highlightAttributes
        }
    }
    
    // Default Attributes used for text while typing
    var typingAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor(hex: "#ffffff")] {
        didSet {
            mentionEditor.typingAttributes = typingAttributes
        }
    }
    
    public weak var delegate: MentionManagerDelegate?

    // Provides list of users for mention
    let mentionProvider: MentionListProvider
    let mentionEditor: MentionTextEditor
    
    public init(withType type: MentionManagerType) {
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
    }
    
    func changeSelection(_ textInput: UITextInput) {
        mentionEditor.changeSelection(textInput)
    }
    
    func shouldChangeTextIn(_ textInput: UITextInput, inRange range: NSRange, replacementText: String, currentText text: String) -> Bool {
        return mentionEditor.processUserInput(in: textInput, range: range, replacementText: replacementText, currentText: text)
    }
    
    func addMention(from textInput: UITextInput, in text: String, at indexPath: IndexPath) {
        guard indexPath.row < mentionProvider.mentionList.count else { return }
        let member = mentionProvider.mentionList[indexPath.row]
        
        mentionEditor.addMention(member: member, textInput: textInput, currentText: text)
    }
    
    func isMentionWithinLimit(limit: Int) -> Bool {
        return mentionEditor.mentions.count < limit
    }
    
    func addMention(from textInput: UITextInput, in text: String, member: AmityMentionUserModel) {
        mentionEditor.addMention(member: member, textInput: textInput, currentText: text)
    }

    func setMentions(metadata: [String: Any], inText text: String) {
        self.mentionEditor.setMentions(metadata: metadata, inText: text)
    }
    
    func getMetadata(shift: Int = 0) -> [String: Any]? {
        if mentionEditor.mentions.isEmpty {
            return nil
        }
        
        let finalMentions = mentionEditor.mentions
        
        if shift != 0 {
            for i in 0..<finalMentions.count {
                finalMentions[i].index += shift
            }
        }
        
        return AmityMentionMapper.metadata(from: finalMentions)
    }
    
    func getMentionees() -> AmityMentioneesBuilder? {
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
    func resetState() {
        mentionEditor.reset()
        mentionProvider.reset()
    }
}
