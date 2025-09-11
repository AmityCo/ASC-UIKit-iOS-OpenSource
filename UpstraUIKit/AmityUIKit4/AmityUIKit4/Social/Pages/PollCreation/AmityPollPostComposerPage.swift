//
//  AmityPollPostComposerPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 7/10/2567 BE.
//

import SwiftUI
import Foundation
import AmitySDK

public enum AmityPollType: String {
    case image
    case text
}

public struct AmityPollPostComposerPage: AmityPageView {
    
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        return .pollPostPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: PollPostComposerViewModel
    @StateObject private var editorViewModel: AmityTextEditorViewModel
    @StateObject private var titleEitorViewModel: AmityTextEditorViewModel
    @State private var pollPostErrorMessage = AmityLocalizedStringSet.Social.pollPostCreateError.localizedString
    
    @State private var question: String = ""
    @State private var title: String = ""
    @State private var isMultipleSelection = false
    @State private var showPollDurationSheet = false
    @State private var selectedDuration: PollDuration = .day30
    @State private var toastMessage: String = AmityLocalizedStringSet.Social.pollPostCreateError.localizedString
    @State private var isToastVisible = false
    @State private var isCreatingPost = false
    @State private var isInputValid = false
    
    struct Constants {
        static let questionMaxCharLimit = 500
        static let titleMaxCharLimit = 150
        static let answerMaxCharLimit = 60
    }
    
    @State private var mentionData: MentionData = MentionData()
    @State private var mentionedUsers: [AmityMentionUserModel] = []
    @State private var isQuestionCharLimitError = false
    @State private var isTitleCharLimitError = false

    @State private var showCloseAlert = false
    let pollType: AmityPollType
    
    public init(targetId: String?, targetType: AmityPostTargetType, pollType: AmityPollType = .text) {
        self._viewModel = StateObject(wrappedValue: PollPostComposerViewModel(targetId: targetId, targetType: targetType))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .pollPostPage))
        self._editorViewModel = StateObject(wrappedValue: AmityTextEditorViewModel(mentionManager: MentionManager(withType: .post(communityId: targetType == .community ? targetId : ""))))
        self.pollType = pollType
        self._titleEitorViewModel = StateObject(wrappedValue: AmityTextEditorViewModel(mentionManager: MentionManager(withType: .post(communityId: targetType == .community ? targetId : "")), textStyle: .titleBold(.black)))
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // My Timeline OR Target Name
                AmityNavigationBar(title: viewModel.pollTarget) {
                    
                    Image(AmityIcon.closeIcon.imageResource)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 24, height: 20)
                        .padding(.vertical, 8)
                        .onTapGesture {
                            if hasContentToDiscard() {
                                showCloseAlert.toggle()
                            } else {
                                host.controller?.navigationController?.dismiss(animated: true)
                            }
                        }
                        .alert(isPresented: $showCloseAlert) {
                            Alert(title: Text(AmityLocalizedStringSet.Social.postDiscardAlertTitle.localizedString), message: Text(AmityLocalizedStringSet.Social.postDiscardAlertMessage.localizedString), primaryButton: .cancel(Text(AmityLocalizedStringSet.Social.postDiscardAlertButtonKeepEditing.localizedString)), secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.discard.localizedString), action: {
                                host.controller?.navigationController?.dismiss(animated: true)
                            }))
                        }
                    
                } trailing: {
                    
                    Button {
                        switch pollType {
                        case .image:
                            createImagePollPost()
                        case .text:
                            createTextPollPost()
                        }
                    } label: {
                        Text(AmityLocalizedStringSet.Social.createPostBottomSheetTitle.localizedString)
                            .applyTextStyle(.body(Color(viewConfig.theme.primaryColor)))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isInputValid)
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        VStack(spacing: 4) {
                            
                            HStack(spacing: 0) {
                                Text(AmityLocalizedStringSet.Social.pollPostTitle.localizedString)
                                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                                
                                Text(AmityLocalizedStringSet.Social.pollPostTitleOptional.localizedString)
                                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade3)))
                                    .padding(.leading, 4)
                                
                                Spacer()
                                
                                Text("\(title.count)/\(Constants.titleMaxCharLimit)")
                                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                                    .accessibilityIdentifier("titleCharCountTextAccessibilityId")
                            }
                            .padding(.bottom, 20)
                            
                            AmityMessageTextEditorView(titleEitorViewModel, text: $title, mentionData: $mentionData, mentionedUsers: $mentionedUsers, initialEditorHeight: 34, maxNumberOfLines: 12, placeholderPadding: 4)
                                .placeholder(AmityLocalizedStringSet.Social.pollPostTitleTextfieldPlaceholder.localizedString)
                                .characterLimit(Constants.titleMaxCharLimit)
                                .onChange(of: title) { newValue in
                                    validateInputs()
                                }
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(isTitleCharLimitError ? Color(viewConfig.theme.alertColor) : Color(viewConfig.theme.baseColorShade4))
                                .padding(.top, 4)
                            
                            if isTitleCharLimitError {
                                HStack {
                                    Text(AmityLocalizedStringSet.Social.pollTitleCharLimitError.localized(arguments: Constants.titleMaxCharLimit))
                                        .applyTextStyle(.caption(Color(viewConfig.theme.alertColor)))
                                        .padding(.top, 4)
                                        .transition(.opacity)
                                    
                                    Spacer()
                                }
                            }
                            
                            HStack {
                                Text(AmityLocalizedStringSet.Social.pollQuestionTitle.localizedString)
                                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                                
                                Spacer()
                                
                                Text("\(question.count)/\(Constants.questionMaxCharLimit)")
                                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                                    .accessibilityIdentifier("charCountTextAccessibilityId")
                            }
                            .padding(.top, 24)
                            .padding(.bottom, 20)
                            
                            AmityMessageTextEditorView(editorViewModel, text: $question, mentionData: $mentionData, mentionedUsers: $mentionedUsers, initialEditorHeight: 34, maxNumberOfLines: 12, placeholderPadding: 4)
                                .placeholder(AmityLocalizedStringSet.Social.pollQuestionTextfieldPlaceholder.localizedString)
                                .characterLimit(Constants.questionMaxCharLimit)
                                .enableHashtagHighlighting(true)
                                .maxHashtagCount(30)
                                .onChange(of: question) { newValue in
                                    validateInputs()
                                }
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                                .padding(.top, 4)
                        }
                        
                        switch pollType {
                        case .image:
                            PollImageOptionSection(viewModel: viewModel)
                                .onChange(of: viewModel.imageOptions) { newValue in
                                    validateInputs()
                                }
                        case .text:
                            PollTextOptionSection(viewModel: viewModel)
                                .onChange(of: viewModel.textOptions) { newValue in
                                    validateInputs()
                                }
                        }
                        
                        Divider()
                        
                        SettingToggleButtonView(isEnabled: $isMultipleSelection, title: AmityLocalizedStringSet.Social.pollMultipleSelectionTitle.localizedString, description: AmityLocalizedStringSet.Social.pollMultipleSelectionDesc.localizedString)
                        
                        Divider()
                        
                        PollDurationSection(duration: $selectedDuration, onTapAction: {
                            hideKeyboard()
                            showPollDurationSheet = true
                        })
                        
                    }
                    .padding()
                }
                .onTapGesture {
                    hideKeyboard()
                }
                .bottomSheet(isShowing: $showPollDurationSheet, height: .contentSize) {
                    PollDurationSelectionView(duration: $selectedDuration, isVisible: $showPollDurationSheet)
                }
            }
            
            loadingIndicator
                .opacity(isCreatingPost ? 1 : 0)
            
            AmityMentionUserListView(mentionedUsers: $mentionedUsers, selection: { selectedMention in
                // Ask view model to handle this selection
                editorViewModel.selectMentionUser(user: selectedMention)
                
                // Update attributed Input
                self.question = editorViewModel.textView.text
                
                mentionData.mentionee = editorViewModel.mentionManager.getMentionees()
                mentionData.metadata = editorViewModel.mentionManager.getMetadata()
                
            }, paginate: {
                editorViewModel.loadMoreMentions()
            })
            .background(Color(viewConfig.theme.backgroundColor))
            .isHidden(mentionedUsers.count == 0)
            .accessibilityIdentifier(AccessibilityID.Chat.MentionList.container)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .showToast(isPresented: $isToastVisible, style: .warning, message: pollPostErrorMessage, bottomPadding: 24)
    }
    
    @ViewBuilder
    var loadingIndicator: some View {
        VStack {
            Color.white.opacity(0.3)
            
            ToastView(message: AmityLocalizedStringSet.Social.pollCreatePostingToast.localizedString, style: .loading)
                .padding(.bottom, 24)
        }
    }
    
    func validateInputs() {
        let isQuestionValid = validatePollQuestion()
        
        var isOptionsValid = true
        
        switch pollType {
        case .image:
            isOptionsValid = validateImagePollOptions()
        case .text:
            isOptionsValid = validateTextPollOptions()
        }
        
        let isTitleValid = validatePollTitle()
        
        isInputValid = isQuestionValid && isOptionsValid && isTitleValid
    }
    
    func validatePollTitle() -> Bool {
        let sanitizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Question cannot be empty
        // guard !sanitizedTitle.isEmpty else { return false }
        
        // Question character count should be less than 500
        guard sanitizedTitle.count <= Constants.titleMaxCharLimit else { return false }
        
        return true
    }
    
    func validatePollQuestion() -> Bool {
        let sanitizedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Question cannot be empty
        guard !sanitizedQuestion.isEmpty else { return false }
        
        // Question character count should be less than 500
        guard sanitizedQuestion.count <= Constants.questionMaxCharLimit else { return false }
        
        return true
    }
    
    func validateTextPollOptions() -> Bool {
        let sanitizedOptions = viewModel.textOptions.compactMap {
            let sanitizedOption = $0.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return sanitizedOption.isEmpty ? nil : sanitizedOption
        }
        
        // There should at least be 2 poll options available
        guard sanitizedOptions.count >= 2 else { return false }
        
        var isAllOptionsValid = true
        for option in sanitizedOptions {
            if option.count > Constants.answerMaxCharLimit {
                isAllOptionsValid = false
                break
            }
        }
        
        return isAllOptionsValid
    }
    
    func validateImagePollOptions() -> Bool {
        let validOptions = viewModel.imageOptions.compactMap { option in
            if let _ = option.imageData {
                return option
            }
            
            return nil
        }
        
        // At least 2 options should be valid with images uploaded
        guard validOptions.count >= 2 else { return false }
        
        let uploadingOptions = viewModel.imageOptions.filter { $0.uploadState == .uploading }
        
        // No options should be in uploading state
        guard uploadingOptions.count == 0 else { return false }
        
        return true
    }
    
    func createTextPollPost() {
        let pollClosedInMilliSeconds: Int = getPollCloseDurationInMilliSeconds()
        
        let answers = viewModel.textOptions.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        isCreatingPost = true
        Task { @MainActor in
            
            do {
                let mentions = AmityMetadataMapper.mentions(fromMetadata: mentionData.metadata ?? [:])
                let hashtags = editorViewModel.existingHashtags.map { AmityHashtag(text: $0.text, index: $0.range.location, length: $0.range.length)}
                let metadata = AmityMetadataMapper.metadata(mentions: mentions, hashtags: hashtags)
                
                let hashtagBuilder = AmityHashtagBuilder()
                hashtagBuilder.hashtags(hashtags: hashtags.map { $0.text })
                
                let post = try await viewModel.createTextPollPost(title: title, question: question, answers: answers, isMultipleSelection: isMultipleSelection, closedIn: pollClosedInMilliSeconds, metadata: metadata, mentionees: mentionData.mentionee, hashtags: hashtagBuilder)
                
                isCreatingPost = false
                
                handleSuccess(post: post)
            } catch {
                isCreatingPost = false
                
                handleError(error: error)
            }
        }
    }
    
    func createImagePollPost() {
        let pollClosedInMilliSeconds: Int = getPollCloseDurationInMilliSeconds()
        
        // answers
        let validAnswers = viewModel.imageOptions.compactMap {
            if let imageData = $0.imageData {
                return (imageData, $0.text)
            }
            
            return nil
        }
        
        isCreatingPost = true
        Task { @MainActor in
            do {
                let mentions = AmityMetadataMapper.mentions(fromMetadata: mentionData.metadata ?? [:])
                let hashtags = editorViewModel.existingHashtags.map { AmityHashtag(text: $0.text, index: $0.range.location, length: $0.range.length)}
                let metadata = AmityMetadataMapper.metadata(mentions: mentions, hashtags: hashtags)
                
                let hashtagBuilder = AmityHashtagBuilder()
                hashtagBuilder.hashtags(hashtags: hashtags.map { $0.text })
                
                // create image poll post
                let post = try await viewModel.createImagePollPost(title: title, question: question, answers: validAnswers, isMultipleSelection: isMultipleSelection, closedIn: pollClosedInMilliSeconds, metadata: metadata, mentionees: mentionData.mentionee, hashtags: hashtagBuilder)
                
                isCreatingPost = false
                
                handleSuccess(post: post)
            } catch {
                isCreatingPost = false
                
                handleError(error: error)
            }
        }
    }
    
    func handleSuccess(post: AmityPost) {
        host.controller?.navigationController?.dismiss(animated: true, completion: {
            if post.getFeedType() == .reviewing {
                let alertController = UIAlertController(title: "Post sent for review", message: "Your post has been submitted to the pending list. It will be published once approved by the group moderator.", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: AmityLocalizedStringSet.General.okay.localizedString, style: .cancel)
                alertController.addAction(okAction)
                
                UIApplication.topViewController()?.present(alertController, animated: true)
            }
        })
    }
    
    func handleError(error: Error) {
        if error.isAmityErrorCode(.banWordFound) {
            toastMessage = "Your post wasn't posted as it contains an inappropriate word."
        } else if error.isAmityErrorCode(.linkNotAllowed) {
            toastMessage = "Your post wasn't posted as it contains a link that's not allowed."
        } else {
            toastMessage = AmityLocalizedStringSet.Social.pollPostCreateError.localizedString
        }
        
        // Show toast
        withAnimation {
            isToastVisible = true
        }
    }
    
    func getPollCloseDurationInMilliSeconds() -> Int {
        var pollClosedInMilliSeconds: Int = 0
        switch selectedDuration {
        case .day1, .day3, .day7, .day14, .day30:
            pollClosedInMilliSeconds = selectedDuration.unit * 1000 * 60 * 60 * 24
        case .custom(let date):
            let timeInterval = date.timeIntervalSince(Date())
            pollClosedInMilliSeconds = Int(timeInterval * 1000)
        }
        return pollClosedInMilliSeconds
    }
    
    func hasContentToDiscard() -> Bool {
        let pollTitle = self.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let pollQuestion = self.question.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasPollOption = viewModel.isAnyPollOptionEdited()
        
        return !pollTitle.isEmpty || !pollQuestion.isEmpty || hasPollOption
    }
}

struct PollOption: Identifiable, Equatable  {
    
    var id: Int {
        return index
    }
    
    var index: Int
    var text: String
    
    init(text: String = "", index: Int) {
        self.text = text
        self.index = index
    }
    
    static func == (lhs: PollOption, rhs: PollOption) -> Bool {
        return lhs.index == rhs.index && lhs.text == rhs.text
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(index)
    }
    
}

struct PollSectionHeader: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
            
            Text(description)
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
        }
    }
}
