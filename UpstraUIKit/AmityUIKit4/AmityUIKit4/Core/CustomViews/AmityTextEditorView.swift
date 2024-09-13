//
//  AmityTextEditorView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 3/6/24.
//

import Foundation
import SwiftUI
import Combine

public enum MentionListPosition: Equatable {
    case top(CGFloat)
    case bottom(CGFloat)
    /// case where mention list should be out of TextEditor
    case none
}

extension AmityTextEditorView: AmityViewBuildable {
    
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
    
    public func textColor(_ value: UIColor) -> Self {
        mutating(keyPath: \.textColor, value: value)
    }
    
    public func backgroundColor(_ value: UIColor) -> Self {
        mutating(keyPath: \.backgroundColor, value: value)
    }
    
    public func hightlightColor(_ value: UIColor) -> Self {
        mutating(keyPath: \.hightlightColor, value: value)
    }
}


public struct AmityTextEditorView: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    @Binding private var text: String
    
    @Binding private var mentionData: MentionData
    
    @State private var mentionedUsers: [AmityMentionUserModel] = []
    
    @State private var textEditorHeight: CGFloat = 0.0
    
    @State private var textEditorInitialHeight: CGFloat = 24
    
    @State private var hidePlaceholder: Bool = false
    
    @StateObject private var viewModel: AmityTextEditorViewModel
    
    private var placeholder: String = ""
    
    private var textEditorMaxHeight: CGFloat = 120
   
    private var mentionListPosition: MentionListPosition = .top(20)
    
    private var willShowMentionList: ((CGFloat) -> Void)?
    
    private var autoFocusTextEditor: Bool = false
    
    private var textColor: UIColor = .black
    
    private var backgroundColor: UIColor = .white
    
    private var hightlightColor: UIColor = .blue

    public init(_ mentionManagerType: MentionManagerType, text: Binding<String>, mentionData: Binding<MentionData>, textViewHeight: CGFloat) {
        self._text = text
        self._mentionData = mentionData
        self._textEditorHeight = State(initialValue: textViewHeight)
        
        let mentionManger = MentionManager(withType: mentionManagerType)

        self._viewModel = StateObject(wrappedValue: AmityTextEditorViewModel(mentionManager: mentionManger))
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                TextEditorView(viewModel, $text, $mentionedUsers)
                    .onAppear {
                        textEditorInitialHeight = geometry.size.height
                        
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
                        self.mentionData.metadata = viewModel.mentionManager.getMetadata()
                        self.mentionData.mentionee = viewModel.mentionManager.getMentionees()
                        self.text = text
                    })
                    .onChange(of: mentionedUsers.count) { count in
                        let listHeight = mentionedUsers.count < 5 ? CGFloat(mentionedUsers.count) * 50.0 : 250.0
                        willShowMentionList?(listHeight)
                    }
                    .overlay(
                        VStack {
                            if mentionListPosition != MentionListPosition.none {
                                let listHeight = mentionedUsers.count < 5 ? CGFloat(mentionedUsers.count) * 50.0 : 250.0
                                
                                ScrollViewReader { scrollViewReader in
                                    ScrollView {
                                        LazyVStack {
                                            ForEach(Array(mentionedUsers.enumerated()), id: \.element.userId) { index, user in
                                                HStack {
                                                    AsyncImage(placeholder: AmityIcon.defaultCommunityAvatar.getImageResource(), url: URL(string: user.avatarURL))
                                                        .frame(width: 30, height: 30)
                                                        .clipShape(Circle())
                                                    
                                                    Text(user.displayName)
                                                        .foregroundColor(Color(textColor))
                                                    
                                                    if user.isBrand {
                                                        Image(AmityIcon.brandBadge.imageResource)
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 18, height: 18)
                                                            .opacity(user.isBrand ? 1 : 0)
                                                    }
                                                    
                                                    Spacer()
                                                }
                                                .padding([.leading, .trailing], 15)
                                                .padding([.top, .bottom], 10)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    let indexPath = IndexPath(row: index, section: 0)
                                                    viewModel.mentionManager.addMention(from: viewModel.textView, in: viewModel.textView.text, at: indexPath)
                                                    
                                                    self.text = viewModel.textView.text
                                                    mentionData.metadata = viewModel.mentionManager.getMetadata()
                                                    mentionData.mentionee = viewModel.mentionManager.getMentionees()
                                                }
                                                .onAppear {
                                                    if index == mentionedUsers.count - 1  {
                                                        viewModel.mentionManager.mentionProvider.loadMore()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .frame(width: UIScreen.main.bounds.width, height: listHeight)
                                .background(Color(backgroundColor))
                                .offset(y: getOverlayOffset(size: geometry.size, listHeight: listHeight, position: mentionListPosition))
                                .isHidden(mentionedUsers.count == 0)
                            }
                        }
                    )
                
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
        .onReceive(viewConfig.$theme) { value in
            viewModel.updateAttributes(hightlightColor: value.primaryColor, textColor: value.baseColor)
        }
        .frame(height: textEditorHeight)
    }
    
    
    private func getOverlayOffset(size: CGSize, listHeight: CGFloat, position: MentionListPosition) -> CGFloat {
        switch position {
        case .top(let padding):
            -(listHeight / 2 + size.height / 2 + padding)
        case .bottom(let padding):
            listHeight / 2 + size.height / 2 + padding
        case .none:
            0.0
        }
    }
}

public class AmityTextEditorViewModel: ObservableObject {
    let textView: UITextView = UITextView(frame: .zero)
    let mentionManager: MentionManager
    @Published var reachMentionLimit = false
    
    // Attributes used to highlight mentions
    var highlightAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 15, weight: .bold),
        .foregroundColor: UIColor.systemBlue]
    
    // Attributes used for text while typing
    var typingAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 15),
        .foregroundColor: UIColor(hex: "#ffffff")]
    
    init(mentionManager: MentionManager) {
        self.mentionManager = mentionManager
        let existingInset = textView.textContainerInset
        
        self.textView.textContainerInset = UIEdgeInsets(top: 8, left: existingInset.left, bottom: 8, right: existingInset.right)
        self.textView.typingAttributes = typingAttributes

        self.mentionManager.typingAttributes = typingAttributes
        self.mentionManager.highlightAttributes = highlightAttributes
    }
    
    func updateAttributes(hightlightColor: UIColor, textColor: UIColor) {
        self.highlightAttributes = [
            .font: UIFont.systemFont(ofSize: 15, weight: .bold),
            .foregroundColor: hightlightColor]
        
        self.typingAttributes = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: textColor]
        
        self.textView.typingAttributes = typingAttributes

        self.mentionManager.typingAttributes = typingAttributes
        self.mentionManager.highlightAttributes = highlightAttributes
        
        // Apply attribute to existing text
        let attributedText = NSMutableAttributedString(attributedString: self.textView.attributedText)
        attributedText.addAttributes(typingAttributes, range: NSRange(location: 0, length: attributedText.length))
        self.textView.attributedText = attributedText
        
    }
}

// TextEditor + Mention
extension AmityTextEditorViewModel {
    
    func loadMoreMentions() {
        mentionManager.mentionProvider.loadMore()
    }
    
    func selectMentionUser(user: AmityMentionUserModel) {
        guard mentionManager.isMentionWithinLimit(limit: MentionManager.maximumMentionsCount) else {
            reachMentionLimit = true
            return
        }
        
        self.mentionManager.addMention(from: textView, in: textView.text, member: user)
    }
}

// Text View
extension AmityTextEditorViewModel {
    
    func reset() {
        textView.attributedText = NSAttributedString(string: "")
        textView.typingAttributes = self.typingAttributes
        
        // Reset mention state
        mentionManager.resetState()
    }
}

internal struct TextEditorView: UIViewRepresentable {
    
    @ObservedObject var viewModel: AmityTextEditorViewModel
    @Binding var text: String
    @Binding var mentionedUsers: [AmityMentionUserModel]
    
    init(_ viewModel: AmityTextEditorViewModel, _ text: Binding<String>, _ mentionedUsers: Binding<[AmityMentionUserModel]>) {
        self.viewModel = viewModel
        self._text = text
        self._mentionedUsers = mentionedUsers
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        viewModel.mentionManager.delegate = coordinator
        return coordinator
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = viewModel.textView
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 15)
        textView.backgroundColor = .clear
        textView.textColor =  viewModel.typingAttributes[.foregroundColor] as? UIColor
        textView.typingAttributes = context.coordinator.parentView.viewModel.typingAttributes
        //textView.textColor = textColor
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Note: Hack to place cursor in same position while editing attributed text.
        let cursorRange = uiView.selectedTextRange
        guard !text.isEmpty else {
            uiView.text.removeAll()
            uiView.attributedText = NSAttributedString(string: "") // Set it empty
            // Reset typing attributes so that it starts displaying normal text
            uiView.typingAttributes = context.coordinator.parentView.viewModel.typingAttributes
            return
        }
        
        let attributedText = uiView.attributedText
        uiView.text = text
        if !(attributedText?.string.isEmpty ?? false) {
            uiView.attributedText = attributedText
        }
        uiView.selectedTextRange = cursorRange
    }
    
    class Coordinator: NSObject, UITextViewDelegate, MentionManagerDelegate {
        
        let parentView: TextEditorView
        
        init(_ parentView: TextEditorView) {
            self.parentView = parentView
        }
        
        // MARK: UITextViewDelegate
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            return parentView.viewModel.mentionManager.shouldChangeTextIn(textView, inRange: range, replacementText: text, currentText: textView.text)
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            parentView.viewModel.mentionManager.changeSelection(textView)
        }
        
        // MARK: AmityMentionManagerDelegate
        
        func didUpdateMentionUsers(users: [AmityMentionUserModel]) {
            parentView.mentionedUsers = users
            
            // Also reset typing attributes if we stop showing mention users.
            if users.isEmpty {
                parentView.viewModel.textView.typingAttributes = parentView.viewModel.typingAttributes
            }
        }
        
        func didCreateAttributedString(attributedString: NSAttributedString) {
            parentView.viewModel.textView.attributedText = attributedString
            parentView.viewModel.textView.typingAttributes = parentView.viewModel.typingAttributes
        }

    }
}

extension UITextView {

    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.publisher(
            for: UITextView.textDidChangeNotification,
            object: self
        )
        .compactMap { ($0.object as? UITextView)?.text }
        .eraseToAnyPublisher()
    }

}
