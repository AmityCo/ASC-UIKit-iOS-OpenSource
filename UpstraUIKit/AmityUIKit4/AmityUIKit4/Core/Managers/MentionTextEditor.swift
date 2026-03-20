//
//  MentionTextEditor.swift
//  AmityUIKit4
//
//  Created by Nishan on 27/3/2567 BE.
//

import Foundation
import UIKit
import AmitySDK

protocol MentionTextEditorDelegate: AnyObject {
    
    func didChangeMentionState(state: MentionTextEditor.MentionState)
    func didUpdateAttributedText(text: NSAttributedString)
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
                            
                            let deleteLength = range.length
                            for (index, mention) in self.mentions.enumerated() where range.location <= mention.index {
                                mentions[index].index -= deleteLength
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
                        let deleteLength = range.length

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
        
        Log.add(event: .info, "Adding mention \(member.displayName) to index: \(mentionRange.location), length: \(mentionRange.length)")
        
        // Append mention display name to current text (with trailing space that is not part of the mention)
        let searchInput = mentionSearchKey.isEmpty ? "@" : "@\(mentionSearchKey)" // Actual search input in UITextView with "@"
        var finalText = currentText.replacingOccurrences(of: searchInput, with: "@\(member.displayName) ", options: .caseInsensitive, range: Range(mentionRange, in: currentText))
        
        // Note: Remove this logic if we support sending whitespaces + newlines at the beginning of the message text.
        // Remove whitespace occurrence in beginning of the text & adjusts mention range.
        let whitespaces = finalText.prefix { char in
            char.isWhitespace
        }
        mentionRange.location -= whitespaces.count
        // Only trim leading whitespace to preserve the trailing space after the mention
        finalText = String(finalText.drop(while: { $0.isWhitespace }))
        
        // Append mention array
        let mention = AmityMention(type: member.type, index: mentionRange.location, length: member.displayName.count, userId: member.userId)
        mentions.append(mention)
        
        // Determine index to be shifted for existing mentions
        let mentionSearchKeyLength = mentionSearchKey.utf8.count // Length of search key already used
        let mentionOffset = member.displayName.count - mentionSearchKeyLength + 1 // Amount of search text to be replaced (+1 for trailing space).
        Log.add(event: .info, "Mention Offset: \(mentionOffset)")
                
        // Update the length of previous mention
        for (index, mention) in self.mentions.enumerated() where mentionRange.location < mention.index {
            mentions[index].index = mentionOffset + mention.index
        }
        
        // Terminate mention search
        self.mentionSearchKey = ""
        self.updateMentionState(state: .idle)
                
        // Notify mention addition
        Log.add(event: .info, "Final Text: \(finalText)")
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
            // Only check the left side of @ — it must have whitespace or newline before it
            // (or be at the start). The right side doesn't matter because the user is typing
            // new characters after @, and there may already be text to the right when inserting
            // in the middle of existing text.
            let triggerLeftRange = NSRange(location: rangeIndex - 1, length: 1)

            // If left character range is valid
            if NSLocationInRange(triggerLeftRange.location, NSRange(location: 0, length: currentText.utf16.count)) {
                let beforeCharacter = (currentText as NSString).substring(with: triggerLeftRange).trimmingCharacters(in: .whitespacesAndNewlines)
                if !beforeCharacter.isEmpty {
                    return false
                }
            }

            return true
        }
    }
    
    /// Adjusts existing mention indices when the text content changes externally
    /// (e.g., a product tag is added/removed, shifting text around mentions).
    /// Computes the diff between old and new text and updates indices accordingly.
    func adjustIndicesForTextChange(oldText: String, newText: String) {
        let oldNS = oldText as NSString
        let newNS = newText as NSString

        // Find common prefix length
        var prefixLen = 0
        let minLen = min(oldNS.length, newNS.length)
        while prefixLen < minLen && oldNS.character(at: prefixLen) == newNS.character(at: prefixLen) {
            prefixLen += 1
        }

        // Find common suffix length
        var suffixLen = 0
        while suffixLen < minLen - prefixLen
                && oldNS.character(at: oldNS.length - 1 - suffixLen) == newNS.character(at: newNS.length - 1 - suffixLen) {
            suffixLen += 1
        }

        let changeLocation = prefixLen
        let oldChangeLength = oldNS.length - prefixLen - suffixLen
        let newChangeLength = newNS.length - prefixLen - suffixLen
        let lengthDifference = newChangeLength - oldChangeLength

        var indicesToRemove: [Int] = []

        for i in 0..<mentions.count {
            let mentionStart = mentions[i].index

            // Mention is within the changed region → remove it
            if mentionStart >= changeLocation && mentionStart < changeLocation + oldChangeLength {
                indicesToRemove.append(i)
            }
            // Mention is after the changed region → shift
            else if mentionStart >= changeLocation + oldChangeLength {
                mentions[i].index += lengthDifference
            }
        }

        for index in indicesToRemove.reversed() {
            mentions.remove(at: index)
        }
    }

    func reset() {
        mentions = []
        mentionSearchKey = ""
        mentionState = .idle
        mentionRange = .init()
    }

    /// Reset only the current search state without clearing existing mentions
    func resetSearchState() {
        mentionSearchKey = ""
        mentionState = .idle
        mentionRange = .init()
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
