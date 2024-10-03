//
//  ExpandableText.swift
//  ExpandableText
//
//  Created by ned on 23/02/23.
//

import Foundation
import SwiftUI
import AmitySDK

/**
An expandable text view that displays a truncated version of its contents with a "show more" button that expands the view to show the full contents.

 To create a new ExpandableText view, use the init method and provide the initial text string as a parameter. The text string will be automatically trimmed of any leading or trailing whitespace and newline characters.

Example usage with default parameters:
 ```swift
ExpandableText("Lorem ipsum dolor sit amet, consectetur adipiscing elit...")
    .font(.body)
    .foregroundColor(.primary)
    .lineLimit(3)
    .moreButtonText("more")
    .moreButtonColor(.accentColor)
    .expandAnimation(.default)
    .trimMultipleNewlinesWhenTruncated(true)
 ```
*/
public struct ExpandableText: View {

    @State private var isExpanded: Bool = false
    @State private var isTruncated: Bool = false

    @State private var intrinsicSize: CGSize = .zero
    @State private var truncatedSize: CGSize = .zero
    @State private var moreTextSize: CGSize = .zero
    
    internal let text: String
    internal var font: Font = .body
    internal var color: Color = .primary
    internal var lineLimit: Int = 3
    internal var moreButtonText: String = "more"
    internal var moreButtonFont: Font?
    internal var moreButtonColor: Color = .accentColor
    internal var attributedColor: UIColor = UIColor.systemBlue
    internal var expandAnimation: Animation = .default
    internal var collapseEnabled: Bool = false
    internal var trimMultipleNewlinesWhenTruncated: Bool = true
    internal var metadata: [String: Any]?
    internal var mentionees: [AmityMentionees]?
    internal var onTapMentionee: ((String) -> Void)?
    
    /**
     Initializes a new `ExpandableText` instance with the specified text string, trimmed of any leading or trailing whitespace and newline characters.
     - Parameter text: The initial text string to display in the `ExpandableText` view.
     - Returns: A new `ExpandableText` instance with the specified text string and trimming applied.
     */
    public init(_ text: String, metadata: [String: Any]? = nil, mentionees: [AmityMentionees]? = nil, onTapMentionee: ((String) -> Void)? = nil) {
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.metadata = metadata
        self.mentionees = mentionees
        self.onTapMentionee = onTapMentionee
    }
    
    public var body: some View {
        content
            .lineLimit(isExpanded ? nil : lineLimit)
            .applyingTruncationMask(size: moreTextSize, enabled: shouldShowMoreButton)
            .readSize { size in
                truncatedSize = size
                isTruncated = truncatedSize != intrinsicSize
            }
            .background(
                content
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    .readSize { size in
                        intrinsicSize = size
                        isTruncated = truncatedSize != intrinsicSize
                    }
            )
            .background(
                Text(moreButtonText)
                    .font(moreButtonFont ?? font)
                    .hidden()
                    .readSize { moreTextSize = $0 }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if (isExpanded && collapseEnabled) ||
                     shouldShowMoreButton {
                    withAnimation(expandAnimation) { isExpanded.toggle() }
                }
            }
            .modifier(OverlayAdapter(alignment: .trailingLastTextBaseline, view: {
                if shouldShowMoreButton {
                    Button {
                        withAnimation(expandAnimation) { isExpanded.toggle() }
                    } label: {
                        Text(moreButtonText)
                            .font(moreButtonFont ?? font)
                            .foregroundColor(moreButtonColor)
                    }
                }
            }))
    }
    
    @ViewBuilder
    private var content: some View {
        if #available(iOS 15, *) {
            let trimmedText = getAttributedText(text: textTrimmingDoubleNewlines, metadata: metadata ?? [:], mentionees: mentionees ?? [], font: .systemFont(ofSize: 14, weight: .bold))
            let text = getAttributedText(text: text, metadata: metadata ?? [:], mentionees: mentionees ?? [], font: .systemFont(ofSize: 14, weight: .bold))
            
            Text(trimMultipleNewlinesWhenTruncated
                 ? (shouldShowMoreButton ? trimmedText : text)
                 : text)
            .font(font)
            .foregroundColor(color)
            .frame(alignment: .leading)
            .environment(\.openURL, OpenURLAction { url in
                // Tapping on mention user attribute
                if url.deletingLastPathComponent().absoluteString == TextHighlighter.mentionURL {
                    let userId = url.lastPathComponent
                    onTapMentionee?(userId)
                    return .discarded
                }
                
                return .systemAction
            })
        } else {
            Text(.init(
                trimMultipleNewlinesWhenTruncated
                    ? (shouldShowMoreButton ? textTrimmingDoubleNewlines : text)
                    : text
            ))
            .font(font)
            .foregroundColor(color)
            .frame(alignment: .leading)
        }
        
    }

    private var shouldShowMoreButton: Bool {
        !isExpanded && isTruncated
    }
    
    private var textTrimmingDoubleNewlines: String {
        text.replacingOccurrences(of: #"\n\s*\n"#, with: "\n", options: .regularExpression)
    }
}


extension ExpandableText {
    @available(iOS 15, *)
    func getAttributedText(text: String, metadata: [String: Any], mentionees: [AmityMentionees], font: UIFont) -> AttributedString {
        
        let highlightAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: attributedColor, .font: UIFont.systemFont(ofSize: 15, weight: .semibold)]
        
        //let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        //let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        let contentText = text
        var highlightedText = AttributedString(contentText)
        
        // If mention is present, highlight mentions first.
        highlightedText = TextHighlighter.highlightMentions(for: contentText, metadata: metadata, mentionees: mentionees, highlightAttributes: highlightAttributes)
        
        // If links is present, highlight links
        let links = TextHighlighter.detectLinks(in: contentText)
        if !links.isEmpty {
            highlightedText = TextHighlighter.highlightLinks(links: links, in: highlightedText, attributes: highlightAttributes)
        }
        
        return highlightedText
    }
}
