//
//  ProductTagManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/21/26.
//

import Foundation
import AmitySDK

/// Model to track product tags in text
public class AmityProductTagModel: Equatable {
    public enum AmityProductTaggedContent {
        case text, media
    }
    
    public static func == (lhs: AmityProductTagModel, rhs: AmityProductTagModel) -> Bool {
        lhs.productId == rhs.productId
    }
    
    public let productId: String
    public let productName: String
    public var object: AmityProduct
    public var contentType: AmityProductTaggedContent
    public var range: NSRange
    
    public init(object: AmityProduct, range: NSRange, contentType: AmityProductTaggedContent = .text) {
        self.object = object
        self.range = range
        self.contentType = contentType
        self.productId = object.productId
        self.productName = object.productName
    }
}

public protocol ProductTagManagerDelegate: AnyObject {
    func productTagManager(didUpdateAttributedText attributedText: NSAttributedString, cursorPosition: Int)
}

/// Manager class to handle product tag operations in text editor
public class ProductTagManager {
    private weak var textView: UITextView?
    private var highlightAttributes: [NSAttributedString.Key: Any]
    private var typingAttributes: [NSAttributedString.Key: Any]

    /// All tracked product tags
    var productTags: [AmityProductTagModel] = [] {
        didSet {
            onProductTagsChanged?(productTags)
        }
    }

    /// Callback when product tags are updated
    var onProductTagsChanged: (([AmityProductTagModel]) -> Void)?

    /// Delegate notified when product tag operations produce a new attributed text.
    /// Follows the same delegate pattern as MentionManagerDelegate.didCreateAttributedString
    /// so that both systems adjust each other's indices in a centralized handler.
    weak var delegate: ProductTagManagerDelegate?

    /// Flag to indicate selection change should be skipped by other processors
    private(set) var shouldSkipNextSelectionChange: Bool = false

    init(textView: UITextView,
         highlightAttributes: [NSAttributedString.Key: Any],
         typingAttributes: [NSAttributedString.Key: Any]) {
        self.textView = textView
        self.highlightAttributes = highlightAttributes
        self.typingAttributes = typingAttributes
    }

    /// Update attributes (called when theme changes)
    func updateAttributes(highlightAttributes: [NSAttributedString.Key: Any],
                          typingAttributes: [NSAttributedString.Key: Any]) {
        self.highlightAttributes = highlightAttributes
        self.typingAttributes = typingAttributes
    }

    // MARK: - Text Input Processing (similar to MentionManager interface)

    /// Process text changes. Returns false if the change was handled and should not proceed.
    func shouldChangeTextIn(_ textView: UITextView, range: NSRange, replacementText text: String) -> Bool {
        let isDeletion = text.isEmpty

        if isDeletion {
            // Check for backspace at the end of a product tag (single char deletion, no selection).
            // Selects the whole tag so the next delete removes it as a unit.
            if range.length == 1 && textView.selectedRange.length == 0,
               let productTagRange = tagRangeAtCursorEnd(cursorLocation: range.location + range.length) {
                shouldSkipNextSelectionChange = true
                selectTag(range: productTagRange)
                return false
            }
            // When deleting a selected product tag (or any other text), fall through to
            // updateRanges and return true so UITextView handles the deletion naturally.
            // This matches how MentionManager handles mention deletion.
        }

        // Update product tag ranges for any text change that proceeds
        updateRanges(changeRange: range, replacementLength: text.count)
        return true
    }

    /// Process selection changes. Returns false if handled and should skip other processors.
    func changeSelection(_ textView: UITextView) -> Bool {
        if shouldSkipNextSelectionChange {
            shouldSkipNextSelectionChange = false
            return false
        }
        return true
    }

    // MARK: - Product Tag Operations

    /// Add a product tag at the specified location
    func addProductTag(product: AmityProduct, atLocation: Int, cursorPosition: Int) {
        guard let textView = textView else { return }

        let productName = product.productName

        // Calculate the range to replace (from @ to current cursor position)
        let replaceRange = NSRange(location: atLocation, length: cursorPosition - atLocation)

        // Use NSString length for correct UTF-16 code unit count (required for NSRange)
        let productNameLength = (productName as NSString).length

        // Calculate the length difference for updating existing product tag ranges
        // +1 for the trailing space that is appended after the product name
        let lengthDifference = (productNameLength + 1) - replaceRange.length

        // Update existing product tag ranges that come after the insertion point
        for i in 0..<productTags.count {
            if productTags[i].range.location >= replaceRange.location {
                productTags[i].range.location += lengthDifference
            }
        }

        // Create the attributed string with the product name highlighted, followed by a space
        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())

        // Replace the "@keyword" with the product name (highlighted) + trailing space
        let highlightedProductName = NSMutableAttributedString(string: productName, attributes: highlightAttributes)
        highlightedProductName.append(NSAttributedString(string: " ", attributes: typingAttributes))
        attributedText.replaceCharacters(in: replaceRange, with: highlightedProductName)

        // Track the new product tag (range does NOT include the trailing space)
        let productTagRange = NSRange(location: atLocation, length: productNameLength)
        let productTag = AmityProductTagModel(object: product, range: productTagRange)
        productTags.append(productTag)

        // Notify via delegate — the handler sets the text view, adjusts
        // mention indices, and reapplies highlighting.
        let newCursorPosition = atLocation + productNameLength + 1 // +1 to place cursor after the trailing space
        delegate?.productTagManager(didUpdateAttributedText: attributedText, cursorPosition: newCursorPosition)
    }

    /// Reapply product tag highlighting after mention manager updates attributed text
    func reapplyHighlighting() {
        guard let textView = textView, !productTags.isEmpty else { return }

        guard let attributedText = textView.attributedText?.mutableCopy() as? NSMutableAttributedString else {
            return
        }

        for productTag in productTags {
            // Validate the range is still within bounds
            guard productTag.range.location + productTag.range.length <= attributedText.length else { continue }

            // Verify the text at this range still matches the product name
            let textAtRange = (attributedText.string as NSString).substring(with: productTag.range)
            guard textAtRange == productTag.productName else { continue }

            // Apply highlighting
            attributedText.addAttributes(highlightAttributes, range: productTag.range)
        }

        textView.attributedText = attributedText
        textView.typingAttributes = typingAttributes
    }

    /// Reset all product tags and remove highlighting from text view
    func reset() {
        guard let textView = textView else {
            productTags.removeAll()
            return
        }

        // Remove highlighting from product tags in the text view
        if !productTags.isEmpty, let attributedText = textView.attributedText?.mutableCopy() as? NSMutableAttributedString {
            for productTag in productTags {
                // Validate the range is still within bounds
                guard productTag.range.location + productTag.range.length <= attributedText.length else { continue }

                // Remove highlight attributes and apply typing attributes
                attributedText.addAttributes(typingAttributes, range: productTag.range)
            }

            textView.attributedText = attributedText
            textView.typingAttributes = typingAttributes
        }

        productTags.removeAll()
    }

    // MARK: - Range Adjustment

    /// Adjusts product tag ranges when the text content changes externally
    /// (e.g., when a mention is added/removed, changing the text around product tags).
    /// Computes the diff between old and new text and updates ranges accordingly.
    func adjustRangesForTextChange(oldText: String, newText: String) {
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

        updateRanges(changeRange: NSRange(location: changeLocation, length: oldChangeLength),
                     replacementLength: newChangeLength)
    }

    // MARK: - Private Helpers

    private func updateRanges(changeRange: NSRange, replacementLength: Int) {
        let lengthDifference = replacementLength - changeRange.length

        var tagsToRemove: [Int] = []

        for i in 0..<productTags.count {
            let tagRange = productTags[i].range

            // Check if the change is within the product tag (tag should be removed)
            if changeRange.location > tagRange.location && changeRange.location < tagRange.location + tagRange.length {
                tagsToRemove.append(i)
            }
            // Check if change starts at the beginning of the tag or deletes the tag
            else if changeRange.location == tagRange.location && changeRange.length > 0 {
                tagsToRemove.append(i)
            }
            // Check if the change is before the product tag (shift the range)
            else if changeRange.location <= tagRange.location {
                productTags[i].range.location += lengthDifference
            }
        }

        // Remove invalidated tags in reverse order to maintain indices
        for index in tagsToRemove.reversed() {
            productTags.remove(at: index)
        }
    }

    private func tagRangeAtCursorEnd(cursorLocation: Int) -> NSRange? {
        for productTag in productTags {
            let tagEndLocation = productTag.range.location + productTag.range.length
            if cursorLocation == tagEndLocation {
                return productTag.range
            }
        }
        return nil
    }

    private func selectTag(range: NSRange) {
        textView?.selectedRange = range
    }

}
