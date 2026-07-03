//
//  AmityMessageAction.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 10/4/2567 BE.
//

import CoreGraphics

public class AmityMessageAction {

    public typealias MessageAction = (MessageModel) -> Void

    var onCopy: MessageAction?
    var onReply: MessageAction?
    var onDelete: MessageAction?
    /// Cancel an in-flight media upload (aborts + removes the bubble, no dialog).
    /// Distinct from onDelete, which confirms before deleting a synced message.
    var onCancelUpload: MessageAction?
    var onResend: MessageAction?
    var onFailedTap: MessageAction?
    // Should we conbine report and unreport together?
    var onReport: MessageAction?
    var onUnReport: MessageAction?
    var onSaveImage: MessageAction?
    var onSaveVideo: MessageAction?
    var onEdit: MessageAction?
    var onSeeMore: ((String) -> Void)?
    
    // Internally used
    var showReaction: MessageAction?
    var onSeeMoreReplied: ((String) -> Void)?
    
    public init(onCopy: MessageAction?, onReply: MessageAction?, onDelete: MessageAction?, onReport: MessageAction?, onUnReport: MessageAction?, onSaveImage: MessageAction? = nil, onSaveVideo: MessageAction? = nil, onSeeMore: ((String) -> Void)? = nil, onResend: MessageAction? = nil) {
        self.onCopy = onCopy
        self.onReply = onReply
        self.onDelete = onDelete
        self.onReport = onReport
        self.onUnReport = onUnReport
        self.onSaveImage = onSaveImage
        self.onSaveVideo = onSaveVideo
        self.onSeeMore = onSeeMore
        self.onResend = onResend
    }
    
    internal init() { /* Intentionally left empty */ }
}
