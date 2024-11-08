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
    
    public init(_ viewModel: AmityTextEditorViewModel, text: Binding<String>, mentionData: Binding<MentionData>, mentionedUsers: Binding<[AmityMentionUserModel]>, textViewHeight: CGFloat, textEditorMaxHeight: CGFloat = 106) {
        self._text = text
        self._mentionData = mentionData
        self._textEditorHeight = State(initialValue: textViewHeight)
        self._mentionedUsers = mentionedUsers
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.textEditorMaxHeight = textEditorMaxHeight
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
                        
                        if characterLimit > 0, value.count > characterLimit {
                            self.text = String(value.prefix(characterLimit))
                            self.viewModel.textView.text = text
                        }
                        
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
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    .padding(.leading, placeholderPadding)
                    .onTapGesture {
                        viewModel.textView.becomeFirstResponder()
                    }
                    .isHidden(hidePlaceholder)
            }
        }
        .onReceive(viewConfig.$theme, perform: { value in
            viewModel.updateAttributes(hightlightColor: value.primaryColor, textColor: value.baseColor)
        })
        .frame(height: textEditorHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.textView.becomeFirstResponder()
        }
    }
}
