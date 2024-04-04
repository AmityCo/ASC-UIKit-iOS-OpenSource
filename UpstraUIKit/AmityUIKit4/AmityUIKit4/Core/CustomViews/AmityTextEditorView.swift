//
//  AmityTextEditorView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 3/6/24.
//

import Foundation
import SwiftUI
import Combine

public enum MentionListPosition {
    case top(CGFloat)
    case bottom(CGFloat)
}


extension AmityTextEditorView: AmityViewBuildable {
    
    public func placeholder(_ value: String) -> Self {
        mutating(keyPath: \.placeholder, value: value)
    }
    
    public func maxExpandableHeight(_ value: CGFloat) -> Self {
        mutating(keyPath: \.textEditorMaxHeight, value: value)
    }
    
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
    
    @Binding private var text: String
    
    @Binding private var mentionData: MentionData
    
    @State private var mentionedUsers: [AmityMentionUserModel] = []
    
    @State private var textEditorHeight: CGFloat = 0.0
    
    @State private var textEditorInitialHeight: CGFloat = 0.0
    
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
                TextEditorView(viewModel, $text, $mentionedUsers, textColor, hightlightColor)
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
                        textEditorHeight = min(max(textHeight, textEditorInitialHeight), textEditorMaxHeight)
                    }
                    .onReceive(viewModel.textView.textPublisher, perform: { text in
                        self.text = text
                    })
                    .onChange(of: mentionedUsers.count) { count in
                        let listHeight = mentionedUsers.count < 5 ? CGFloat(mentionedUsers.count) * 50.0 : 250.0
                        willShowMentionList?(listHeight)
                    }
                    .overlay(
                        VStack {
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
                                                    viewModel.mentionManager.loadMore()
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
        .frame(height: textEditorHeight)
    }
    
    
    private func getOverlayOffset(size: CGSize, listHeight: CGFloat, position: MentionListPosition) -> CGFloat {
        switch position {
        case .top(let padding):
            -(listHeight / 2 + size.height / 2 + padding)
        case .bottom(let padding):
            listHeight / 2 + size.height / 2 + padding
        }
    }
}

private class AmityTextEditorViewModel: ObservableObject {
    let textView: UITextView = UITextView(frame: .zero)
    let mentionManager: MentionManager
    
    init(mentionManager: MentionManager) {
        self.mentionManager = mentionManager
    }
}


private struct TextEditorView: UIViewRepresentable {
    
    @ObservedObject var viewModel: AmityTextEditorViewModel
    @Binding var text: String
    @Binding var mentionedUsers: [AmityMentionUserModel]
    let textColor: UIColor
    let hightlightColor: UIColor
    
    init(_ viewModel: AmityTextEditorViewModel, _ text: Binding<String>, _ mentionedUsers: Binding<[AmityMentionUserModel]>, _ textColor: UIColor, _ hightlightColor: UIColor) {
        self.viewModel = viewModel
        self._text = text
        self._mentionedUsers = mentionedUsers
        self.textColor = textColor
        self.hightlightColor = hightlightColor
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        viewModel.mentionManager.delegate = coordinator
        viewModel.mentionManager.foregroundColor = textColor
        viewModel.mentionManager.highlightColor = hightlightColor
        return coordinator
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = viewModel.textView
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 15)
        textView.backgroundColor = .clear
        textView.textColor = textColor
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        guard !text.isEmpty else {
            uiView.text.removeAll()
            return
        }
        
        let attributedText = uiView.attributedText
        uiView.text = text
        if !(attributedText?.string.isEmpty ?? false) {
            uiView.attributedText = attributedText
        }
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
        func didGetUsers(users: [AmityMentionUserModel]) {
            parentView.mentionedUsers = users
        }
        
        func didCreateAttributedString(attributedString: NSAttributedString) {
            parentView.viewModel.textView.attributedText = attributedString
            parentView.viewModel.textView.typingAttributes = [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: parentView.textColor]
        }
        
        func didMentionsReachToMaximumLimit() {
            //
        }
        
        func didCharactersReachToMaximumLimit() {
            //
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
