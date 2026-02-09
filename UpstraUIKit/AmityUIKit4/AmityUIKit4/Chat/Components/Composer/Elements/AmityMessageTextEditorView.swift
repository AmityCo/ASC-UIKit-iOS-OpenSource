//
//  AmityMessageTextEditorView.swift
//  AmityUIKit4
//
//  Created by Nishan on 25/3/2567 BE.
//

import SwiftUI

extension AmityMessageTextEditorView: AmityViewBuildable {
    
    public func placeholder(_ value: String) -> Self {
        mutating(keyPath: \.placeholder, value: value)
    }
    
    public func maxExpandableHeight(_ value: CGFloat) -> Self {
        mutating(keyPath: \.textEditorMaxHeight, value: value)
    }
    
    public func autoFocus(_ value: Bool) -> Self {
        mutating(keyPath: \.autoFocusTextEditor, value: value)
    }
    
    public func characterLimit(_ value: Int) -> Self {
        mutating(keyPath: \.characterLimit, value: value)
    }
    
    public func enableHashtagHighlighting(_ value: Bool) -> Self {
        mutating(keyPath: \.enableHashtagHighlighting, value: value)
    }
    
    public func maxHashtagCount(_ value: Int) -> Self {
        mutating(keyPath: \.maxHashtagCount, value: value)
    }

    public func scrollEnabled(_ value: Bool) -> Self {
        mutating(keyPath: \.scrollEnabled, value: value)
    }
}

public struct AmityMessageTextEditorView: View {
    
    @Binding private var text: String
    @Binding private var mentionData: MentionData
    @Binding private var mentionedUsers: [AmityMentionUserModel]
    
    @State private var textEditorHeight: CGFloat = 0.0
    @State private var hidePlaceholder: Bool = false
    
    @StateObject private var viewModel: AmityTextEditorViewModel
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    private var placeholder: String = ""
    private var textEditorMaxHeight: CGFloat = 106 // 5 lines (18 px per line) + textContainerInset.top + textContainerInset.bottom
    private var willShowMentionList: ((CGFloat) -> Void)?
    private var autoFocusTextEditor: Bool = false
    private var characterLimit: Int = 0
    private var placeholderPadding: CGFloat = 5
    private var enableHashtagHighlighting: Bool = false
    private var maxHashtagCount: Int = 5
    private var scrollEnabled: Bool = true
    
    public init(_ viewModel: AmityTextEditorViewModel, text: Binding<String>, mentionData: Binding<MentionData>, mentionedUsers: Binding<[AmityMentionUserModel]>, textViewHeight: CGFloat, textEditorMaxHeight: CGFloat = 106) {
        self._text = text
        self._mentionData = mentionData
        self._textEditorHeight = State(initialValue: textViewHeight)
        self._mentionedUsers = mentionedUsers
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.textEditorMaxHeight = textEditorMaxHeight
        self._hidePlaceholder = State(initialValue: !text.wrappedValue.isEmpty ? true : false)
    }
    
    public init(
        _ viewModel: AmityTextEditorViewModel,
        text: Binding<String>,
        mentionData: Binding<MentionData>,
        mentionedUsers: Binding<[AmityMentionUserModel]>,
        initialEditorHeight: CGFloat = 34,
        maxNumberOfLines: Int = 5,
        placeholderPadding: CGFloat = 5
    ) {
        self._text = text
        self._mentionData = mentionData
        self._textEditorHeight = State(initialValue: initialEditorHeight)
        self._mentionedUsers = mentionedUsers
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.textEditorMaxHeight = CGFloat(maxNumberOfLines) * 18 + viewModel.textView.textContainerInset.top + viewModel.textView.textContainerInset.bottom
        self.placeholderPadding = placeholderPadding
        self._hidePlaceholder = State(initialValue: !text.wrappedValue.isEmpty ? true : false)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                TextEditorView(viewModel, $text, $mentionedUsers)
                    .onAppear {
                        viewModel.isScrollEnabled = scrollEnabled

                        if autoFocusTextEditor {
                            viewModel.textView.becomeFirstResponder()
                        }

                        if let metadata = mentionData.metadata {
                            viewModel.mentionManager.setMentions(metadata: metadata, inText: text)
                        }
                        
                        // Set up hashtag highlighting callback
                        if enableHashtagHighlighting {
                            // Apply hashtag highlighting immediately when the view appears
                            applyHashtagHighlighting(to: viewModel.textView)
                            
                            // Reapply hashtag highlighting when mentionee are highlighted
                            viewModel.reapplyHashtagHighlighting = {
                                DispatchQueue.main.async {
                                    self.applyHashtagHighlighting(to: self.viewModel.textView)
                                }
                            }
                        }
                    }
                    .onChange(of: text) { value in
                        hidePlaceholder = !text.isEmpty
                        
                        if characterLimit > 0, value.utf16Count > characterLimit {
                            self.text = value.utf16Prefix(characterLimit)
                            self.viewModel.textView.text = text
                        }
                        
                        // Use UITextView's own size calculation which accounts for
                        // textContainerInset and lineFragmentPadding correctly
                        let fittingSize = viewModel.textView.sizeThatFits(CGSize(width: geometry.size.width, height: .greatestFiniteMagnitude))
                        textEditorHeight = min(fittingSize.height, textEditorMaxHeight)
                    }
                    .onReceive(viewModel.textView.textPublisher, perform: { text in
                        self.text = text
                        
                        self.mentionData.metadata = viewModel.mentionManager.getMetadata()
                        self.mentionData.mentionee = viewModel.mentionManager.getMentionees()
                        
                        // Apply hashtag highlighting after a short delay to ensure mentions are processed first
                        if enableHashtagHighlighting {
                            applyHashtagHighlighting(to: viewModel.textView)
                        }
                    })
                
                Text(placeholder)
                    .applyTextStyle(viewModel.textStyle?.withColor(Color(viewConfig.theme.baseColorShade3)) ?? .body(Color(viewConfig.theme.baseColorShade3)))
                    .padding(.leading, placeholderPadding)
                    .allowsHitTesting(false)
                    .isHidden(hidePlaceholder)
            }
        }
        .onReceive(viewConfig.$theme, perform: { value in
            viewModel.updateAttributes(hightlightColor: value.primaryColor, textColor: value.baseColor)
            
            // Reapply hashtag highlighting when theme changes
            if enableHashtagHighlighting {
                applyHashtagHighlighting(to: viewModel.textView)
            }
        })
        .frame(height: textEditorHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.textView.becomeFirstResponder()
        }
    }
    
    // MARK: - Hashtag Highlighting
    private func applyHashtagHighlighting(to textView: UITextView) {
        guard let attributedText = textView.attributedText?.mutableCopy() as? NSMutableAttributedString else {
            return
        }
        
        let text = attributedText.string
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        
        // Store current cursor position
        let selectedRange = textView.selectedRange
        
        do {
            // regex if white space is needed at end: (^|\\s)#[\\p{L}\\p{N}\\p{M}_]{1,100}(?=\\s)
            let hashtagRegex = try NSRegularExpression(pattern: "(?<=^|\\s)#[\\p{L}\\p{N}\\p{M}_]{1,100}", options: [])
            let matches = hashtagRegex.matches(in: text, range: fullRange)
            
            if matches.count > maxHashtagCount {
                if viewModel.reachHashtagLimit == false {
                    viewModel.reachHashtagLimit = true
                }
            }
            
            // Get the first matches
            let limitedMatches = matches.prefix(maxHashtagCount)
            
            // Sanitize and store the hashtags
            viewModel.existingHashtags = limitedMatches.map({ match in
                let range = match.range
                let text = String(text[Range(match.range, in: text)!])
                
                /// Need to Sanitize the range and text.
                /// In this text, "#abc #def hey",
                /// regex will match - '#abc' and ' #def'
                /// we need to store - # as the start location and abc - 3 as length without counting the space and #
                let sanitizedText = String(text.filter { !$0.isWhitespace && $0 != "#" })
                let sanitizedCount = text.utf16.count - sanitizedText.utf16.count
                let sanitizedLocation = range.location == 0 ? 0 : range.location + (sanitizedCount - 1) // -1 is to start location from #
                let sanitizedRange = NSRange(location: sanitizedLocation, length: sanitizedText.utf16.count)
                
                return AmityHashtagModel(text: sanitizedText, range: sanitizedRange)
            })
            
            // Remove all hashtag attributes from the existing attributed text
            attributedText.enumerateAttributes(in: fullRange) { attribute, range, _ in
                if attribute[.hashtag] as? Bool == true {
                    attributedText.removeAttribute(.foregroundColor, range: range)
                    attributedText.removeAttribute(.hashtag, range: range)
                }
            }
            
            // Apply hashtag highlighting
            for hashtag in limitedMatches {
                attributedText.addAttribute(.foregroundColor, value: viewModel.highlightAttributes[.foregroundColor] ?? UIColor(), range: hashtag.range)
                attributedText.addAttribute(.hashtag, value: true, range: hashtag.range)
            }
            
            // Apply the attributed text back to the text view
            textView.attributedText = attributedText
            
            // Restore cursor position
            textView.selectedRange = selectedRange
            
            // Ensure typing attributes are maintained
            textView.typingAttributes = viewModel.typingAttributes
            
        } catch {
            Log.warn("Hashtag regex error: \(error)")
        }
    }
}

struct AmityHashtagModel {
    let text: String
    let range: NSRange
}
