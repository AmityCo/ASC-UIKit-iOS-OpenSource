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
    
    /// Will show mention list with provided height
    /// - Parameter value: Height of mention list
    public func willShowMentionList(_ value:((CGFloat) -> Void)?) -> Self {
        mutating(keyPath: \.willShowMentionList, value: value)
    }
    
    public func mentionListPosition(_ value: MentionListPosition) -> Self {
        mutating(keyPath: \.mentionListPosition, value: value)
    }
    
    public func autoFocus(_ value: Bool) -> Self {
        mutating(keyPath: \.autoFocusTextEditor, value: value)
    }
}

public struct AmityMessageTextEditorView: View {
    
    @Binding private var text: String
    @Binding private var mentionData: MentionData
    @Binding private var mentionedUsers: [AmityMentionUserModel]
    
    @State private var textEditorHeight: CGFloat = 0.0
    @State private var hidePlaceholder: Bool = false
    
    @StateObject private var viewModel: AmityTextEditorViewModel
    
    private var placeholder: String = ""
    private var textEditorMaxHeight: CGFloat = 106 // 5 lines (18 px per line) + textContainerInset.top + textContainerInset.bottom
    private var mentionListPosition: MentionListPosition = .top(20)
    private var willShowMentionList: ((CGFloat) -> Void)?
    private var autoFocusTextEditor: Bool = false
    
    public init(_ viewModel: AmityTextEditorViewModel, text: Binding<String>, mentionData: Binding<MentionData>, mentionedUsers: Binding<[AmityMentionUserModel]>, textViewHeight: CGFloat) {
        self._text = text
        self._mentionData = mentionData
        self._textEditorHeight = State(initialValue: textViewHeight)
        self._mentionedUsers = mentionedUsers
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                TextEditorView(viewModel, $text, $mentionedUsers)
                    .onAppear {
                        if autoFocusTextEditor {
                            viewModel.textView.becomeFirstResponder()
                        }
                        
                        if let metadata = mentionData.metadata {
                            viewModel.mentionManager.setMentions(metadata: metadata, inText: text)
                        }
                    }
                    .onChange(of: text) { value in
                        hidePlaceholder = !text.isEmpty
                        let textHeight = viewModel.textView.text.height(withConstrainedWidth: geometry.size.width, font: .systemFont(ofSize: 15))
                        
                        let defaultInset = viewModel.textView.textContainerInset
                        
                        // Note:
                        // Max 5 lines = 90 (18px per line) | Top + Bottom Inset: 16 | ~ Max height: 106
                        
                        let paddedHeight = textHeight + defaultInset.top + defaultInset.bottom
                        textEditorHeight = min(paddedHeight, textEditorMaxHeight)
                    }
                    .onReceive(viewModel.textView.textPublisher, perform: { text in
                        self.text = text
                        
                        self.mentionData.metadata = viewModel.mentionManager.getMetadata()
                        self.mentionData.mentionee = viewModel.mentionManager.getMentionees()
                    })
                
                Text(placeholder)
                    .font(.system(size: 15))
                    .foregroundColor(Color(UIColor(hex: "#898E9E")))
                    .padding(.leading, 5)
                    .onTapGesture {
                        viewModel.textView.becomeFirstResponder()
                    }
                    .isHidden(hidePlaceholder)
            }
        }
        .frame(height: textEditorHeight)
    }
}
