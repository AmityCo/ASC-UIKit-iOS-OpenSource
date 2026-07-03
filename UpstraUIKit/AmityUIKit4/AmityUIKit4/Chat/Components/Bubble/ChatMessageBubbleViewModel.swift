//
//  ChatMessageBubbleViewModel.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK
import Combine

class ChatMessageBubbleViewModel: ObservableObject {
    let message: MessageModel
    let chatManager = ChatManager()
    
    @Published var repliedMessage: MessageModel.RepliedMessage?
    @Published var repliedParent: MessageModel?
    @Published var isReportedByMe: Bool = false
    var token: AmityNotificationToken?
    
    var currentPosition: CGPoint = CGPoint(x: 0, y: 0)
    var currentFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    var errorIconFrame: CGRect = .zero
    
    init(message: MessageModel) {
        self.message = message

        if let flagged = message.isFlaggedByMe {
            self.isReportedByMe = flagged
        }

        updateParentMessageForReply(message: message)
        updateReportStatus(message: message)
    }
    
    func updateParentMessageForReply(message: MessageModel) {
        guard let parentId = message.parentId else { return }

        func makeReplied(from cached: MessageModel) -> MessageModel.RepliedMessage {
            let thumbnailURL = cached.videoThumbnailURL
            let imgURL = cached.mediumFileURL ?? cached.imageURL
            return MessageModel.RepliedMessage(
                displayName: cached.displayName,
                userId: cached.userId,
                text: cached.text,
                type: cached.type,
                isDeleted: cached.isDeleted,
                imageURL: imgURL,
                videoThumbnailURL: thumbnailURL
            )
        }

        func makeRepliedFromSnapshot(_ snapshot: AmityMessage?) -> MessageModel.RepliedMessage {
            let type = snapshot?.messageType ?? .text
            let isDeleted = snapshot?.isDeleted ?? false
            let text = snapshot?.data?["text"] as? String ?? ""
            let isUserDeleted = snapshot?.user?.isDeleted ?? false
            let displayName = isUserDeleted
                ? AmityLocalizedStringSet.Chat.deletedUser.localizedString
                : (snapshot?.user?.displayName ?? "")
            let userId = snapshot?.userId ?? ""

            let imageURL: URL? = {
                guard let info = snapshot?.getImageInfo() else { return nil }
                return URL(string: info.mediumFileURL) ?? URL(string: info.fileURL)
            }()

            let videoThumbnailURL: URL? = {
                guard let fileURLString = snapshot?.getVideoThumbnailInfo()?.fileURL else { return nil }
                return URL(string: fileURLString)
            }()

            return MessageModel.RepliedMessage(
                displayName: displayName,
                userId: userId,
                text: text,
                type: type,
                isDeleted: isDeleted,
                imageURL: imageURL,
                videoThumbnailURL: videoThumbnailURL
            )
        }

        if let cacheMessage = MessageCache.shared.cachedParentMessage[parentId] {
            repliedMessage = makeReplied(from: cacheMessage)
            repliedParent = cacheMessage
        }
        token = chatManager.getMessage(messageId: parentId).observe { [weak self] liveObject, _ in
            let snapshot = liveObject.snapshot
            DispatchQueue.main.async {
                self?.repliedMessage = makeRepliedFromSnapshot(snapshot)
                self?.repliedParent = snapshot.map { MessageModel(message: $0) }
            }
        }
    }
    
    func updateReportStatus(message: MessageModel) {
        if message.flagCount > 0 {
            fetchOwnerReportStatus(message: message)
        } else {
            MessageCache.shared.setFlagStatus(messageId: message.id, value: false)
        }
    }

    func refreshFlagStatus() {
        fetchOwnerReportStatus(message: message)
    }

    func fetchOwnerReportStatus(message: MessageModel) {
        let messageId = message.id
        Task { @MainActor [weak self] in
            guard let self else { return }
            
            let reportStatus = try await self.chatManager.isMessageFlaggedByMe(messageId: messageId)
            
            MessageCache.shared.setFlagStatus(messageId: messageId, value: reportStatus)
            self.isReportedByMe = reportStatus
        }
    }
}
