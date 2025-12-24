//
//  NotificationTrayPageViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 2/4/25.
//

import SwiftUI
import AmitySDK

class AmityNotificationTrayPageViewModel: ObservableObject {
    
    let trayManager = NotificationTrayManager()
    
    @Published var hasUnseenNotification = false
    @Published var sections = [NotificationSection]()
    @Published var isLoading = false
    
    private var collection: AmityCollection<AmityNotificationTrayItem>?
    
    var token: AmityNotificationToken?
        
    init() {
        fetchNotifications()
    }
        
    func fetchNotifications() {
        guard !isLoading else { return }
        
        isLoading = true
        
        collection = trayManager.getNotificationTrayItems()
        token = collection?.observe { [weak self] liveCollection, _, error in
            guard let self else { return }
            
            if let error {
                // Note: Investigate more on this later...
                // When a live collection observation token is still valid & user logs out, sdk logic invalidates all live collection. This also notifies all live collection
                // observers with error with error code unknown (80000). In our usecase this can happen if user login / logout / login immediately.
                // So we prevent showing toast in this case.
                if error.isAmityErrorCode(.unknown) {
                    return
                } else {
                    Toast.showToast(style: .warning, message: "Oops, something went wrong")
                }
                
                return
            }
            
            isLoading = false
            
            var recentItemBucket = [NotificationItem]()
            var oldItemBucket = [NotificationItem]()
            
            liveCollection.snapshots.forEach { item in
                if item.isRecent {
                    recentItemBucket.append(NotificationItem(model: item))
                } else {
                    oldItemBucket.append(NotificationItem(model: item))
                }
            }
            
            var finalSections: [NotificationSection] = []
            if !recentItemBucket.isEmpty {
                finalSections.append(NotificationSection(title: "Recent", notifications: recentItemBucket))
            }
            
            if !oldItemBucket.isEmpty {
                finalSections.append(NotificationSection(title: "Older", notifications: oldItemBucket))
            }
            
            self.sections = finalSections
        }
    }
    
    func fetchMoreNotifications() {
        guard let hasNext = collection?.hasNext, hasNext else { return }
        
        collection?.nextPage()
    }
    
    func markTraySeen() {
        Task { @MainActor in
            try await trayManager.markTrayAsSeen()
        }
    }
    
    func markTrayItemSeen(item: NotificationItem) {
        Task { @MainActor in
            try await item.object.markSeen()
        }
    }
}

struct NotificationSection: Identifiable {
    let id: UUID = UUID()
    let title: String
    let notifications: [NotificationItem]
}

struct NotificationItem: Identifiable {
    
    enum ItemCategory: String {
        case mentionInPoll = "mention_in_poll"
        case mentionInPost = "mention_in_post"
        case mentionInComment = "mention_in_comment"
        case mentionInReply = "mention_in_reply"
        case reactionOnComment = "reaction_on_comment"
        case reactionOnPost = "reaction_on_post"
        case reactionOnReply = "reaction_on_reply"
        case respondOnJoinRequest = "respond_on_join_request"
        case eventStarted = "event_started"
        case eventReminder = "event_reminder"
        case eventCreated = "event_created"
        case inviteRoomCoHost = "room_cohost_invite"
        case none = ""
    }
    
    enum ActionType: String {
        case post
        case poll
        case comment
        case reaction
        case mention
        case reply
        case follow
        case joinRequest = "join_request"
        case event
        case invitation
    }
    
    enum TargetType: String {
        case user
        case community
        case room
    }
    
    let id: String
    let text: String
    let template: String
    let timestamp: Date
    let users: [AmityUserModel]
    let data: [NotificationTemplateData]
    let isSeen: Bool
    let lastSeenAt: Date?
    let lastOccurredAt: Date?
    let actionType: ActionType
    let targetId: String
    let targetType: TargetType
    let trayItemCategory: ItemCategory
    let object: AmityNotificationTrayItem
    
    let actionReferenceId: String
    let referenceId: String
    let referenceType: String
    let parentId: String?
    let event: AmityEvent?

    init(model: AmityNotificationTrayItem) {
        self.id = model.notificationId
        self.text = model.text
        self.template = model.templatedText
        self.timestamp = model.lastOccurredAt
        self.users = model.users.map { AmityUserModel(user: $0) }
        
        let parser = NotificationParser()
        self.data = parser.parse(text: text, template: template)
        self.isSeen = model.isSeen
        self.lastSeenAt = model.lastSeenAt
        self.lastOccurredAt = model.lastOccurredAt
        self.actionType = ActionType(rawValue: model.actionType) ?? .post
        self.targetId = model.targetId
        self.targetType = TargetType(rawValue: model.targetType) ?? .user
        self.trayItemCategory = ItemCategory(rawValue: model.trayItemCategory) ?? .none
        self.actionReferenceId = model.actionReferenceId
        self.referenceId = model.referenceId
        self.referenceType = model.referenceType
        self.parentId = model.parentId
        self.object = model
        self.event = model.event
    }
    
    @available(iOS 15, *)
    func getHighlightedText() -> AttributedString {
        let highlightValues = data.map { ($0.text, $0.range)}
        return TextHighlighter.highlightTexts(texts: highlightValues, in: AttributedString(text), attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .semibold)])
    }
    
    var info: NotificationInfo {
        return NotificationInfo(item: self)
    }
    
    struct NotificationInfo {
        
        let communityId: String?
        var postId: String?
        var commentId: String?
        var parentId: String?
        var userId: String?
        var eventId: String?
        var roomId: String?
        
        init(item: NotificationItem) {
            switch item.actionType {
            case .post, .poll:
                self.postId = item.targetType == .community ? nil : item.actionReferenceId
            case .comment, .reply:
                postId = item.referenceId
                commentId = item.actionReferenceId
            case .reaction:
                switch item.trayItemCategory {
                case .reactionOnComment, .reactionOnReply:
                    postId = item.referenceId
                    commentId = item.actionReferenceId
                case .reactionOnPost:
                    postId = item.actionReferenceId
                default:
                    postId = nil
                }
            case .mention:
                switch item.trayItemCategory {
                case .mentionInPoll, .mentionInPost:
                    postId = item.actionReferenceId
                case .mentionInComment:
                    commentId = item.actionReferenceId
                    postId = item.referenceId
                case .mentionInReply:
                    commentId = item.actionReferenceId
                    postId = item.referenceId
                default:
                    break
                }
            case .joinRequest:
                break
            case .follow:
                userId = item.users.first?.userId
            case .event:
                eventId = item.actionReferenceId
            case .invitation:
                if item.targetType == .room {
                    roomId = item.targetId
                }
            }
            
            parentId = item.parentId
            communityId = item.targetType == .community ? item.object.targetId : nil
        }
    }
}


extension AmityNotificationTrayItem {
    
    var modelDescription: String {
        return """
          Tray Item:
          Notification Id: \(notificationId)
          Last seen at: \(String(describing: lastSeenAt))
          Last occurred at: \(lastOccurredAt)
          Actor Ids: \(actors)
          Actor Count: \(actorCount)
          Action Type: \(actionType)
          Tray Item Category: \(trayItemCategory)
          Target Id: \(targetId)
          Target Type: \(targetType)
          Reference Id: \(referenceId)
          Reference Type: \(referenceType)
          Action Reference Id: \(actionReferenceId)
          Parent Id: \(parentId)
          Text: \(text)
          Template: \(templatedText)
          """
    }
}
