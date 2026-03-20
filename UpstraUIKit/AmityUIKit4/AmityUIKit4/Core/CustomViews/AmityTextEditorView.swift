//
//  AmityTextEditorView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 3/6/24.
//

import Foundation
import SwiftUI
import Combine
import AmitySDK

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

    private var textEditorMinHeight: CGFloat = 0.0

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
        self.textEditorMinHeight = textViewHeight
        
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
                        textEditorHeight = max(textEditorMinHeight, min(paddedHeight, textEditorMaxHeight))
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
                    .applyTextStyle(.body(Color(UIColor(hex: "#898E9E"))))
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
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

// MARK: - AmityTextEditorViewModel

public class AmityTextEditorViewModel: ObservableObject {
    let textView: UITextView = UITextView(frame: .zero)
    let mentionManager: MentionManager
    let linkManager = AmityPreviewLinkWizard.shared
    let textStyle: AmityTextStyle?
    @Published var reachMentionLimit = false
    var existingHashtags: [AmityHashtagModel] = []
    @Published var reachHashtagLimit = false
    var isScrollEnabled: Bool = true
    
    @Published var reachProductTagLimit = false

    /// Closure to check if more product tags can be added (set by parent view)
    var canAddProductTag: (() -> Bool)?

    // Suggestion view state
    @Published var showSuggestionView: Bool = false
    @Published var suggestionViewCursorRect: CGRect = .zero
    private var atSymbolLocation: Int?

    // Suggestion view model (uses mentionManager for user search)
    let suggestionViewModel: TextEditorSuggestionViewModel = TextEditorSuggestionViewModel()

    // Product tag manager
    private(set) var productTagManager: ProductTagManager!

    // Published property for product tags to trigger SwiftUI updates
    @Published private(set) var productTags: [AmityProductTagModel] = []

    // Callback to reapply hashtag highlighting after mention processing
    var didFinishMentionHighlight: (() -> Void)?

    // Attributes used to highlight mentions
    var highlightAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 15, weight: .bold),
        .foregroundColor: UIColor.systemBlue]

    // Attributes used for text while typing
    var typingAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 15),
        .foregroundColor: UIColor(hex: "#ffffff")]

    init(mentionManager: MentionManager, textStyle: AmityTextStyle? = nil) {
        self.mentionManager = mentionManager
        let existingInset = textView.textContainerInset
        if let textStyle {
            self.typingAttributes = [
                .font: UIFont.systemFont(ofSize: textStyle.getStyle().fontSize, weight: textStyle.getStyle().weight.convertToUIFontWeight()),
                .foregroundColor: UIColor(hex: "#ffffff")]

            self.highlightAttributes = [
                .font: UIFont.systemFont(ofSize: textStyle.getStyle().fontSize, weight: .bold),
                .foregroundColor: UIColor.systemBlue]
        }

        self.textView.textContainerInset = UIEdgeInsets(top: 8, left: existingInset.left, bottom: 8, right: existingInset.right)
        self.textView.typingAttributes = typingAttributes

        self.mentionManager.typingAttributes = typingAttributes
        self.mentionManager.highlightAttributes = highlightAttributes
        self.textStyle = textStyle

        // Initialize product tag manager
        self.productTagManager = ProductTagManager(
            textView: textView,
            highlightAttributes: highlightAttributes,
            typingAttributes: typingAttributes
        )

        // Set up callback to update published property when product tags change
        self.productTagManager.onProductTagsChanged = { [weak self] tags in
            self?.productTags = tags
        }

        // Observe keyboard notifications
        setupKeyboardObservers()
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                SuggestionOverlayWindow.updateKeyboardHeight(keyboardFrame.height)
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            SuggestionOverlayWindow.updateKeyboardHeight(0)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateAttributes(hightlightColor: UIColor, textColor: UIColor) {
        if let textStyle {
            self.typingAttributes = [
                .font: UIFont.systemFont(ofSize: textStyle.getStyle().fontSize, weight: textStyle.getStyle().weight.convertToUIFontWeight()),
                .foregroundColor: textColor]

            self.highlightAttributes = [
                .font: UIFont.systemFont(ofSize: textStyle.getStyle().fontSize, weight: .bold),
                .foregroundColor: hightlightColor]
        } else {

            self.highlightAttributes = [
                .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                .foregroundColor: hightlightColor]

            self.typingAttributes = [
                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: textColor]
        }


        self.textView.typingAttributes = typingAttributes

        self.mentionManager.typingAttributes = typingAttributes
        self.mentionManager.highlightAttributes = highlightAttributes

        // Update product tag manager attributes
        self.productTagManager.updateAttributes(
            highlightAttributes: highlightAttributes,
            typingAttributes: typingAttributes
        )

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

        // Reset product tags
        productTagManager.reset()
    }
}

// MARK: - Centralized Text Processing Pipeline
extension AmityTextEditorViewModel {

    /// Processes text changes from UITextViewDelegate by running productTagManager
    /// and mentionManager sequentially. Returns false if the change should be rejected.
    func processTextChange(in textView: UITextView, range: NSRange, replacementText text: String) -> Bool {
        // 1. Product tag processing (may reject the change)
        guard productTagManager.shouldChangeTextIn(textView, range: range, replacementText: text) else {
            return false
        }

        // 2. Suggestion view processing for "@" character
        handleTextChange(in: textView, replacementText: text, range: range)

        // 3. Mention processing
        return mentionManager.shouldChangeTextIn(textView, inRange: range, replacementText: text, currentText: textView.text)
    }

    /// Processes selection changes from UITextViewDelegate by running productTagManager
    /// and mentionManager sequentially.
    func processSelectionChange(in textView: UITextView) {
        // 1. Product tag selection processing (may skip mention processing)
        guard productTagManager.changeSelection(textView) else {
            return
        }

        // 2. Mention selection processing
        mentionManager.changeSelection(textView)
    }

    /// Processes attributed text updates from MentionManager by reapplying product tag
    /// and hashtag/link highlighting sequentially.
    func processMentionTextUpdate(attributedString: NSAttributedString) {
        // Capture old text before applying the new attributed string so we can
        // detect text-content changes (e.g. mention added/removed) and adjust
        // product tag ranges accordingly.
        let oldText = textView.text ?? ""
        let newText = attributedString.string

        textView.attributedText = attributedString
        textView.typingAttributes = typingAttributes

        // 1. Adjust product tag ranges if the text content changed
        if oldText != newText {
            productTagManager.adjustRangesForTextChange(oldText: oldText, newText: newText)
        }

        // 2. Reapply product tag highlighting
        productTagManager.reapplyHighlighting()

        // 3. Reapply hashtag/link highlighting if callback is set
        didFinishMentionHighlight?()
    }

    /// Processes attributed text updates from ProductTagManager (mirrors processAttributedTextUpdate).
    /// Sets the text view, adjusts mention indices. Call sites update the binding manually,
    /// matching the same pattern as MentionManagerDelegate.didCreateAttributedString.
    func processProductTagTextUpdate(attributedText: NSAttributedString, cursorPosition: Int) {
        let oldText = textView.text ?? ""
        let newText = attributedText.string

        // 1. Apply the attributed text to the text view
        textView.attributedText = attributedText
        textView.selectedRange = NSRange(location: cursorPosition, length: 0)
        textView.typingAttributes = typingAttributes

        // 2. Adjust mention indices if the text content changed
        if oldText != newText {
            mentionManager.adjustIndicesForTextChange(oldText: oldText, newText: newText)
        }

        // 3. Reapply hashtag/link highlighting if callback is set
        didFinishMentionHighlight?()
    }
}

// Suggestion View
extension AmityTextEditorViewModel {

    func handleTextChange(in textView: UITextView, replacementText text: String, range: NSRange) {
        // Check if "@" was typed
        if text == "@" {
            let currentText = textView.text ?? ""
            let isAtStart = range.location == 0
            let hasSpaceBefore: Bool = {
                guard range.location > 0 else { return false }
                let previousIndex = currentText.index(currentText.startIndex, offsetBy: range.location - 1)
                let previousChar = currentText[previousIndex]
                return previousChar == " " || previousChar == "\n"
            }()

            // Only show suggestion if @ is at start or has space/newline before it
            if isAtStart || hasSpaceBefore {
                atSymbolLocation = range.location
                suggestionViewModel.searchKeyword = ""
                updateCursorRect()
                showSuggestionView = true
            }
        } else if let atLocation = atSymbolLocation {
            if text.isEmpty {
                // Deletion
                if range.location <= atLocation {
                    // Deleted the "@" symbol or before it
                    hideSuggestionView()
                } else if !suggestionViewModel.searchKeyword.isEmpty {
                    // Backspace within the keyword area
                    let charsToRemove = min(range.length, suggestionViewModel.searchKeyword.count)
                    suggestionViewModel.searchKeyword = String(suggestionViewModel.searchKeyword.dropLast(charsToRemove))
                    updateCursorRect()
                } else {
                    // No keyword left, deleting "@" next
                    hideSuggestionView()
                }
            } else if text.contains("\n") {
                // Newline typed → close suggestion view
                hideSuggestionView()
            } else {
                // Regular character typed after "@" → accumulate keyword
                suggestionViewModel.searchKeyword += text
                updateCursorRect()
            }
        }
    }

    func updateCursorRect() {
        guard let selectedRange = textView.selectedTextRange else { return }
        let caretRect = textView.caretRect(for: selectedRange.start)

        // Convert to window coordinates
        if let window = textView.window {
            let rectInWindow = textView.convert(caretRect, to: window)
            suggestionViewCursorRect = rectInWindow
        }
    }

    func hideSuggestionView() {
        showSuggestionView = false
        atSymbolLocation = nil
        suggestionViewModel.searchKeyword = ""
    }

    func selectProduct(product: AmityProduct) {
        guard let atLocation = atSymbolLocation else {
            hideSuggestionView()
            return
        }

        // Check if more product tags can be added
        if let canAdd = canAddProductTag, !canAdd() {
            reachProductTagLimit = true
            hideSuggestionView()
            return
        }

        let cursorPosition = textView.selectedRange.location
        productTagManager.addProductTag(
            product: product,
            atLocation: atLocation,
            cursorPosition: cursorPosition
        )
        // Mention index adjustment is handled by processProductTagTextUpdate callback

        // Reset mention manager's search state since we used @ for product instead
        mentionManager.resetSearchState()

        hideSuggestionView()
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
        viewModel.productTagManager.delegate = coordinator
        return coordinator
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = viewModel.textView
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 15)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = viewModel.isScrollEnabled
        textView.smartInsertDeleteType = .no
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.textColor =  viewModel.typingAttributes[.foregroundColor] as? UIColor
        textView.typingAttributes = context.coordinator.parentView.viewModel.typingAttributes
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

        // Only sync binding → UITextView when not actively editing.
        // When the user is typing (isFirstResponder), the UITextView is the source of truth
        // and the binding catches up via textPublisher. Overwriting during active editing
        // causes text loss because @Published property changes (e.g. showSuggestionView)
        // can trigger updateUIView before the text binding reflects the latest input.
        if uiView.text != text && !uiView.isFirstResponder {
            let attributedText = uiView.attributedText
            uiView.text = text
            if !(attributedText?.string.isEmpty ?? false) {
                uiView.attributedText = attributedText
            }
            uiView.selectedTextRange = cursorRange
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate, MentionManagerDelegate, ProductTagManagerDelegate {

        let parentView: TextEditorView

        init(_ parentView: TextEditorView) {
            self.parentView = parentView
        }

        // MARK: - UITextViewDelegate

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            return parentView.viewModel.processTextChange(in: textView, range: range, replacementText: text)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            parentView.viewModel.processSelectionChange(in: textView)
        }

        // MARK: - MentionManagerDelegate

        func didUpdateMentionUsers(users: [AmityMentionUserModel]) {
            parentView.mentionedUsers = users

            // Forward mention users to suggestion view model
            parentView.viewModel.suggestionViewModel.users = users

            // Also reset typing attributes if we stop showing mention users.
            if users.isEmpty {
                parentView.viewModel.textView.typingAttributes = parentView.viewModel.typingAttributes
            }
        }

        // MARK: - MentionManagerDelegate
        func didCreateAttributedString(attributedString: NSAttributedString) {
            parentView.viewModel.processMentionTextUpdate(attributedString: attributedString)
        }

        // MARK: - ProductTagManagerDelegate
        func productTagManager(didUpdateAttributedText attributedText: NSAttributedString, cursorPosition: Int) {
            parentView.viewModel.processProductTagTextUpdate(attributedText: attributedText, cursorPosition: cursorPosition)
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

// MARK: - Suggestion Overlay Window
class SuggestionOverlayWindow {
    static var shared: SuggestionOverlayWindow?
    private static var containerView: UIView = UIView()
    private static var contentView: UIView = UIView()
    private static let suggestionHeight: CGFloat = 185
    private static var keyboardHeight: CGFloat = 0

    static func updateKeyboardHeight(_ height: CGFloat) {
        keyboardHeight = height
    }

    private static func calculateYPosition(cursorRect: CGRect, screenBounds: CGRect) -> CGFloat {
        // Calculate visible area above keyboard
        let visibleHeight = screenBounds.height - keyboardHeight
        let spaceAbove = cursorRect.minY
        let spaceBelow = visibleHeight - cursorRect.maxY

        // Prefer showing below cursor, but if not enough space, show above
        if spaceBelow >= suggestionHeight + 10 {
            // Enough space below cursor (position under)
            return cursorRect.maxY + 10
        } else if spaceAbove >= suggestionHeight + 10 {
            // Not enough space below, but enough above (position above cursor)
            return cursorRect.minY - suggestionHeight - 10
        } else {
            // Not enough space either way (position at top of visible area)
            return max(10, visibleHeight - suggestionHeight - 10)
        }
    }

    static func show<Content: View>(
        at cursorRect: CGRect,
        content: Content,
        viewConfig: AmityViewConfigController
    ) {
        dismiss()

        let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
        guard let window = keyWindow else { return }

        let screenBounds = window.bounds
        let suggestionWidth: CGFloat = screenBounds.width
        let yPosition = calculateYPosition(cursorRect: cursorRect, screenBounds: screenBounds)

        let wrappedContent = AnyView(
            content
                .environmentObject(viewConfig)
                .padding(.horizontal, 8)
        )

        // Suggestion content view
        let hostingController = UIHostingController(rootView: wrappedContent)
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = CGRect(
            x: 0,
            y: yPosition,
            width: suggestionWidth,
            height: suggestionHeight
        )
        contentView = hostingController.view

        // Container view to capture taps outside suggestion view
        containerView = UIView(frame: screenBounds)
        containerView.addSubview(contentView)

        // Set tap gesture to dismiss on outside tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        containerView.addGestureRecognizer(tapGesture)

        window.addSubview(containerView)
    }

    static func updatePosition(at cursorRect: CGRect) {
        let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
        guard let window = keyWindow else { return }

        let screenBounds = window.bounds
        contentView.frame.origin.y = calculateYPosition(cursorRect: cursorRect, screenBounds: screenBounds)
    }

    @objc static func dismiss() {
        containerView.removeFromSuperview()
    }
}
