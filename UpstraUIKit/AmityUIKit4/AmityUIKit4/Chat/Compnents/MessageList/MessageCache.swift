//
//  MessageCache.swift
//  AmityUIKit4
//
//  Created by Nishan on 21/4/2567 BE.
//

import Foundation

// We use this shared message cache to store informations which we do not want to fetch
// everytime when message appears in the list.
class MessageCache {
    
    static var shared = MessageCache()
    
    private init() { /* Shared cache to keep parent message & flag status */}
    
    var cachedParentMessage = [String: MessageModel]()    
    var flagCache = [String: Bool]()

    func appendMessage(message: MessageModel) {
        cachedParentMessage[message.id] = message
    }
    
    // Parent message for the reply. Here message is the parent message
    func setParentMessage(message: MessageModel) {
        cachedParentMessage[message.id] = message
    }
    
    // Returns parent message for given message
    func getParentMessage(for reply: MessageModel) -> MessageModel? {
        if let parentId = reply.parentId {
            return cachedParentMessage[parentId]
        }
        return nil
    }
    
    // Flag Cache
    func isFlaggedByMe(messageId: String) -> Bool? {
        return flagCache[messageId]
    }
    
    func setFlagStatus(messageId: String, value: Bool) {
        flagCache[messageId] = value
    }
}
