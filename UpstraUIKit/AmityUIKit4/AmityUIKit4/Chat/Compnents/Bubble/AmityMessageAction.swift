//
//  AmityMessageAction.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 10/4/2567 BE.
//

public class AmityMessageAction {
    
    public typealias MessageAction = (MessageModel) -> Void
    
    var onCopy: MessageAction?
    var onReply: MessageAction?
    var onDelete: MessageAction?
    // Should we conbine report and unreport together?
    var onReport: MessageAction?
    var onUnReport: MessageAction?
    
    // Internally used
    var showReaction: MessageAction?
    
    public init(onCopy: MessageAction?, onReply: MessageAction?, onDelete: MessageAction?, onReport: MessageAction?, onUnReport: MessageAction?) {
        self.onCopy = onCopy
        self.onReply = onReply
        self.onDelete = onDelete
        self.onReport = onReport
        self.onUnReport = onUnReport
    }
    
    internal init() { /* Intentionally left empty */ }
}
