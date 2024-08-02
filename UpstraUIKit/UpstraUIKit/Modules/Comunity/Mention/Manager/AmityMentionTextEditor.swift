//
//  AmityMentionTextEditor.swift
//  AmityUIKit
//
//  Created by Nishan on 8/7/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//
import Foundation
import UIKit
import AmitySDK

protocol MentionTextEditorDelegate: AnyObject {
    
    func didChangeMentionState(state: MentionTextEditor.MentionState)
    func didUpdateAttributedText(text: NSAttributedString)
}

extension AmityMention: CustomStringConvertible {
    
    public var description: String {
        return "Mention: \(self.userId ?? "") | Index: \(self.index) | Length: \(self.length)"
    }
}

/// Highlights mentions in Text Editor
class MentionTextEditor {
    
    enum MentionState {
        case idle // Mention
        case search(key: String) // Mention Started
    }
    
    private let mentionTrigger = "@"
    private var mentionSearchKey = "" // This is used for searching in sdk. It does not include initial "@" character.
    private var mentionRange = NSRange.init() // Range where mention search gets triggered. This includes initial "@" character.

    private(set) var mentionState = MentionState.idle
    private(set) var mentions: [AmityMention] = [] // Mentions which are added to the text
    
    weak var delegate: MentionTextEditorDelegate?
    
    // Attributes used to highlight mentions
    var highlightAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 15, weight: .bold),
        .foregroundColor: UIColor.systemBlue]
    
    // Attributes used for non-highlighted text
    var typingAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 15),
        .foregroundColor: UIColor(hex: "#000000")]
    
    func processUserInput(in textInput: UITextInput, range: NSRange, replacementText: String, currentText: String) -> Bool {
        
        // Mention Trigger
        if replacementText == mentionTrigger  {
            
            // If a new string is added before existing mentions, update index of those mentions.
            for (index, mention) in self.mentions.enumerated() where range.location < mention.index {
                mentions[index].index += replacementText.count
            }
                        
            // Check if "@" is entered as independent character.
            if shouldHandleMentionTrigger(in: textInput, range: range, replacementText: replacementText, currentText: currentText) {
                mentionSearchKey = ""
                self.updateMentionState(state: .search(key: mentionSearchKey))
                
                // If mention range is not initialized yet, initialize it
                if mentionRange.length == 0 {
                    mentionRange = NSRange(location: range.location, length: 1)
                }
            } else {
                // If input is something@ or @something or @@, mention is dismissed.
                mentionSearchKey = ""
                self.updateMentionState(state: .idle)
            }
            
        } else {
            
            if replacementText == "" {
                
                switch mentionState {
                case .idle:
                    // When removing text, we need to remove mention text as a whole. First we check if the text that we
                    // want to remove contains mention.
                    if let foundRange = findMentionWithinRange(range: range) {
                        if foundRange == range {
                            // Remove mentions from array too
                            removeMentionWithinRange(range: range)
                            
                            let deleteLength = range.length + 1
                            for (index, mention) in self.mentions.enumerated() where range.location <= mention.index {
                                mentions[index].index -= deleteLength // There is a space after every mention, range.length + 1 to count total length included the space
                            }
                        } else {
                            // We don't allow deleting individual character of mention, so we highlight the whole mention text if user
                            // tries to delete individual character.
                            if let startPosition = textInput.position(from: textInput.beginningOfDocument, offset: foundRange.location),
                               let endPosition = textInput.position(from: startPosition, offset: foundRange.length) {
                                
                                textInput.selectedTextRange = textInput.textRange(from: startPosition, to: endPosition)
                                return false
                            }
                        }
                    } else {
                        // Didn't find any mention. Update mention ranges if necessary
                        var deleteLength = range.length
                        deleteLength = deleteLength > 1 ? deleteLength + 1 : deleteLength // Selecting word seems to delete space too.
                        
                        for (index, mention) in self.mentions.enumerated() where range.location <= mention.index {
                            mentions[index].index -= deleteLength
                        }
                    }
                    
                case .search(_):
                    // If removal falls within mention text range, remove and search the location
                    if NSLocationInRange(range.location, mentionRange) {
                        // Mention range includes "@" character. If mentionSearchKey is empty but range still falls within mentionRange,
                        // it means that user is removing "@" character.
                        if !mentionSearchKey.isEmpty {
                            mentionSearchKey.removeLast()
                            mentionRange.length -= max(replacementText.count, 1)
                            
                            self.updateMentionState(state: .search(key: mentionSearchKey))
                        } else {
                            // Stop searching
                            self.updateMentionState(state: .idle)
                        }
                    } else {
                        // Removing text outside mention range. We terminate the search.
                        self.updateMentionState(state: .idle)
                    }
                    return true
                }
                
            } else {
                
                switch mentionState {
                case .idle:
                    mentionSearchKey = ""
                    self.updateMentionState(state: .idle)
                    
                case .search(_):
                    mentionSearchKey += replacementText
                    mentionRange.length += replacementText.count
                    self.updateMentionState(state: .search(key: mentionSearchKey))
                }
                
                // If user added text before existing mentions, update it.
                for (index, mention) in self.mentions.enumerated() where range.location < mention.index {
                    mentions[index].index += replacementText.count
                }
            }
        }
        return true
    }
    
    func changeSelection(_ textInput: UITextInput) {
        switch mentionState {
        case .idle:
            guard let selectedRange = textInput.selectedTextRange, selectedRange != textInput.textRange(from: textInput.endOfDocument, to: textInput.endOfDocument), selectedRange != textInput.textRange(from: textInput.beginningOfDocument, to: textInput.beginningOfDocument) else { return }
            
            let cursorPosition = textInput.offset(from: textInput.beginningOfDocument, to: selectedRange.start)
            
            for mention in mentions {
                if mention.index <= cursorPosition && mention.index + mention.length >= cursorPosition, let startPosition = textInput.position(from: textInput.beginningOfDocument, offset: mention.index), let endPosition = textInput.position(from: textInput.beginningOfDocument, offset: mention.index + mention.length + 1)  {
                    if selectedRange == textInput.textRange(from:startPosition, to: endPosition) { return }
                    textInput.selectedTextRange = textInput.textRange(from:startPosition, to: endPosition)
                }
            }
        case .search(_):
            break
        }
    }
    
    func setMentions(metadata: [String: Any], inText text: String) {
        mentions = AmityMentionMapper.mentions(fromMetadata: metadata)
        let highlightedText = highlightMentions(in: text, mentions: mentions, highlightAttributes: highlightAttributes)
        self.delegate?.didUpdateAttributedText(text: highlightedText)
    }
    
    private func findMentionWithinRange(range: NSRange) -> NSRange? {
        // Note: This at the moment doesn't find mention if user selects between two ranges. It works if user is deleting each individual character.
        for mention in mentions {
//          let mentionRange = NSRange(location: mention.index, length: mention.length + 1)
//          if NSLocationInRange(mentionRange.location, range) { return mentionRange }
            if mention.index <= range.location && mention.index + mention.length >= range.location {
                let mentionRange = NSRange(location: mention.index, length: mention.length + 1)
                return mentionRange
            }
        }
        
        return nil
    }
    
    private func removeMentionWithinRange(range: NSRange) {
        var remainingMentions = [AmityMention]()
        
        for mention in mentions {
            if !(mention.index <= range.location && mention.index + mention.length >= range.location) {
                remainingMentions.append(mention)
            }
        }
        
        self.mentions = remainingMentions
    }
    
    private func updateMentionState(state: MentionState) {
        self.mentionState = state
        switch state {
        case .idle:
            self.mentionSearchKey = ""
            self.mentionRange = .init()
        default:
            break
        }
        
        delegate?.didChangeMentionState(state: state)
    }
    
    // When user taps on mention list.
    func addMention(member: AmityMentionUserModel, textInput: UITextInput, currentText: String) {
        // Global banned user cannot be mentioned.
        guard !member.isGlobalBan else { return }
        
        // Range of "@xyz" in current text. If range != 0, it means that mention search is in progress.
        guard mentionRange.length != 0 else {
            Log.warn("Trying to add mention when mention range is not set")
            return
        }
        
        //Log.add(event: .info, "Adding mention \(member.displayName) to index: \(mentionRange.location), length: \(mentionRange.length)")
        
        // Append mention display name to current text
        let searchInput = mentionSearchKey.isEmpty ? "@" : "@\(mentionSearchKey)" // Actual search input in UITextView with "@"
        var finalText = currentText.replacingOccurrences(of: searchInput, with: "@\(member.displayName)", options: .caseInsensitive, range: Range(mentionRange, in: currentText))
        
        // Note: Remove this logic if we support sending whitespaces + newlines at the beginning of the message text.
        // Remove whitespace occurrence in beginning of the text & adjusts mention range.
        let whitespaces = finalText.prefix { char in
            char.isWhitespace
        }
        mentionRange.location -= whitespaces.count
        finalText = finalText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Append mention array
        let mention = AmityMention(type: member.type, index: mentionRange.location, length: member.displayName.count, userId: member.userId)
        mentions.append(mention)
        
        // Determine index to be shifted for existing mentions
        let mentionSearchKeyLength = mentionSearchKey.utf8.count // Length of search key already used
        let mentionOffset = member.displayName.count - mentionSearchKeyLength // Amount of search text to be replaced.
        //Log.add(event: .info, "Mention Offset: \(mentionOffset)")
                
        // Update the length of previous mention
        for (index, mention) in self.mentions.enumerated() where mentionRange.location < mention.index {
            mentions[index].index = mentionOffset + mention.index
        }
        
        // Terminate mention search
        self.mentionSearchKey = ""
        self.updateMentionState(state: .idle)
                
        // Notify mention addition
        //Log.add(event: .info, "Final Text: \(finalText)")
        let highlightedText = self.highlightMentions(in: finalText, mentions: mentions, highlightAttributes: highlightAttributes)
        self.delegate?.didUpdateAttributedText(text: highlightedText)
    }
    
    // We want to handle mention trigger only if "@" character is entered independently. Not if any other text has "@" as a
    // prefix or suffix.
    private func shouldHandleMentionTrigger(in textInput: UITextInput, range: NSRange, replacementText: String, currentText: String) -> Bool {
        let rangeIndex = range.location
        let existingText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Range of mention trigger in this string
        //let triggerRange = Range(range, in: currentText)
        
        if existingText.isEmpty {
            return true
        } else {
            // Determine text on left & right side of the @ character
            let triggerLeftRange = NSRange(location: rangeIndex - 1, length: 1)
            let triggerRightRange = NSRange(location: rangeIndex + 1, length: 1)
            
            var isMentionAllowed = true
            
            // If left character range is valid
            if NSLocationInRange(triggerLeftRange.location, NSRange(location: 0, length: currentText.utf16.count)) {
                let beforeCharacter = (currentText as NSString).substring(with: triggerLeftRange).trimmingCharacters(in: .whitespacesAndNewlines)
                if !beforeCharacter.isEmpty {
                    isMentionAllowed = false
                }
            }
            
            // If Right character is valid.
            if NSLocationInRange(triggerRightRange.location, NSRange(location: 0, length: currentText.utf16.count)) {
                let afterCharacter = (currentText as NSString).substring(with: triggerLeftRange).trimmingCharacters(in: .whitespacesAndNewlines)
                if !afterCharacter.isEmpty {
                    isMentionAllowed = false
                }
            }
            
            return isMentionAllowed
        }
    }
    
    func reset() {
        mentions = []
        mentionSearchKey = ""
        mentionState = .idle
    }
}

// Highlighter
extension MentionTextEditor {
    // Highlight all mentions in a text & returns attributed string
    func highlightMentions(in text: String, mentions: [AmityMention], highlightAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        
        let attributedString = NSMutableAttributedString(string: text, attributes: typingAttributes)
        
        // We generate attributes for part of the text that needs to be highlighted.
        for mention in mentions {
            if mention.index < 0 || mention.length <= 0 { continue }
            
            // Create range for highlighting that text. Here length + 1 is for '@' character.
            let range = NSRange(location: mention.index, length: mention.length + 1)
            
            if range.location != NSNotFound && (range.location + range.length) <= text.count {
                attributedString.addAttributes(highlightAttributes, range: range)
            }
        }
        
        return attributedString
    }
}
