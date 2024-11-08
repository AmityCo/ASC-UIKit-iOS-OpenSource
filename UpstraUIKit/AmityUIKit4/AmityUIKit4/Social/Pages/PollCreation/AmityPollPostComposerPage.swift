//
//  AmityPollPostComposerPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 7/10/2567 BE.
//

import SwiftUI
import Foundation
import AmitySDK

public struct AmityPollPostComposerPage: AmityPageView {
    
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        return .pollPostPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: PollPostComposerViewModel
    @StateObject private var editorViewModel: AmityTextEditorViewModel
    
    @State private var question: String = ""
    @State private var isMultipleSelection = false
    @State private var showPollDurationSheet = false
    @State private var selectedDuration: PollDuration = .day30
    @State private var isToastVisible = false
    @State private var isCreatingPost = false
    @State private var isInputValid = false
    
    struct Constants {
        static let questionMaxCharLimit = 500
        static let answerMaxCharLimit = 60
    }
    
    @State private var mentionData: MentionData = MentionData()
    @State private var mentionedUsers: [AmityMentionUserModel] = []
    
    @State private var isQuestionCharLimitError = false
    
    public init(targetId: String?, targetType: AmityPostTargetType) {
        self._viewModel = StateObject(wrappedValue: PollPostComposerViewModel(targetId: targetId, targetType: targetType))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .pollPostPage))
        self._editorViewModel = StateObject(wrappedValue: AmityTextEditorViewModel(mentionManager: MentionManager(withType: .post(communityId: targetType == .community ? targetId : ""))))
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // My Timeline OR Target Name
                AmityNavigationBar(title: viewModel.pollTarget) {
                    
                    Image(AmityIcon.closeIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 24, height: 24)
                        .padding(.leading, -6)
                        .onTapGesture {
                            host.controller?.navigationController?.dismiss(animated: true)
                        }
                    
                } trailing: {
                    
                    Button {
                        
                        var pollClosedInMilliSeconds: Int = 0
                        switch selectedDuration {
                        case .day1, .day3, .day7, .day14, .day30:
                            pollClosedInMilliSeconds = selectedDuration.unit * 1000 * 60 * 60 * 24
                        case .custom(let date):
                            let timeInterval = date.timeIntervalSince(Date())
                            pollClosedInMilliSeconds = Int(timeInterval * 1000)
                        }
                        
                        let answers = viewModel.options.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                        
                        isCreatingPost = true
                        Task { @MainActor in
                            
                            do {
                                try await viewModel.createPollPost(question: question, answers: answers, isMultipleSelection: isMultipleSelection, closedIn: pollClosedInMilliSeconds, metadata: mentionData.metadata, mentionees: mentionData.mentionee)
                                
                                isCreatingPost = false
                                
                                host.controller?.navigationController?.dismiss(animated: true)
                            } catch {
                                withAnimation {
                                    isToastVisible = true
                                }
                            }
                        }
                        
                    } label: {
                        Text(AmityLocalizedStringSet.Social.createPostBottomSheetTitle.localizedString)
                            .applyTextStyle(.body(Color(viewConfig.theme.primaryColor)))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isInputValid)
                }
                .padding(.horizontal)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text(AmityLocalizedStringSet.Social.pollQuestionTitle.localizedString)
                                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                                
                                Spacer()
                                
                                Text("\(question.count)/\(Constants.questionMaxCharLimit)")
                                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                                    .accessibilityIdentifier("charCountTextAccessibilityId")
                            }
                            .padding(.bottom, 20)
                            
                            AmityMessageTextEditorView(editorViewModel, text: $question, mentionData: $mentionData, mentionedUsers: $mentionedUsers, initialEditorHeight: 34, maxNumberOfLines: 12, placeholderPadding: 4)
                                .placeholder(AmityLocalizedStringSet.Social.pollQuestionTextfieldPlaceholder.localizedString)
                                .onChange(of: question) { newValue in
                                    withAnimation {
                                        isQuestionCharLimitError = newValue.count > Constants.questionMaxCharLimit
                                    }
                                    
                                    validateInputs()
                                }
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(isQuestionCharLimitError ? Color(viewConfig.theme.alertColor) : Color(viewConfig.theme.baseColorShade4))
                                .padding(.top, 4)
                            
                            if isQuestionCharLimitError {
                                HStack {
                                    Text(AmityLocalizedStringSet.Social.pollQuestionCharLimitError.localized(arguments: Constants.questionMaxCharLimit))
                                        .applyTextStyle(.caption(Color(viewConfig.theme.alertColor)))
                                        .padding(.top, 4)
                                        .transition(.opacity)
                                    
                                    Spacer()
                                }
                            }
                        }
                        
                        PollOptionSection(viewModel: viewModel)
                            .onChange(of: viewModel.options) { newValue in
                                validateInputs()
                            }
                        
                        Divider()
                        
                        SettingToggleButtonView(isEnabled: $isMultipleSelection, title: AmityLocalizedStringSet.Social.pollMultipleSelectionTitle.localizedString, description: AmityLocalizedStringSet.Social.pollMultipleSelectionDesc.localizedString)
                        
                        Divider()
                        
                        PollDurationSection(duration: $selectedDuration, onTapAction: {
                            showPollDurationSheet = true
                        })
                        
                    }
                    .padding()
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
        .updateTheme(with: viewConfig)
        .showToast(isPresented: $isToastVisible, style: .warning, message: AmityLocalizedStringSet.Social.pollPostCreateError.localizedString, bottomPadding: 24)
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
        let isOptionsValid = validatePollOptions()
        
        isInputValid = isQuestionValid && isOptionsValid
    }
    
    func validatePollQuestion() -> Bool {
        let sanitizedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Question cannot be empty
        guard !sanitizedQuestion.isEmpty else { return false }
        
        // Question character count should be less than 500
        guard sanitizedQuestion.count <= Constants.questionMaxCharLimit else { return false }
        
        return true
    }
    
    func validatePollOptions() -> Bool {
        let sanitizedOptions = viewModel.options.compactMap {
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
}

#if DEBUG
#Preview {
    AmityPollPostComposerPage(targetId: nil, targetType: .community)
        .environmentObject(AmityViewConfigController(pageId: .pollPostPage))
}
#endif

struct PollDurationSection: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @Binding var duration: PollDuration
    var onTapAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            PollSectionHeader(title: AmityLocalizedStringSet.Social.pollDurationTitle.localizedString, description: AmityLocalizedStringSet.Social.pollDurationDesc.localizedString)
            
            Button(action: {
                onTapAction()
            }, label: {
                VStack(spacing: 0) {
                    HStack {
                        Text(duration.value)
                            .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                    }
                    .padding(.bottom, 16)
                    .padding(.top, 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    
                    Divider()
                }
            })
            
            if !duration.isCustomDate {
                let endDate = Calendar.current.date(byAdding: .day, value: duration.unit, to: Date())
                Text(AmityLocalizedStringSet.Social.pollEndsOnLabel.localizedString + " " + Formatters.pollDurationFormatter.string(from: endDate ?? Date()))
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
            }
        }
    }
}

struct PollOptionSection: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @ObservedObject var viewModel: PollPostComposerViewModel
    
    private let maxNoOfOptions = 10
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            PollSectionHeader(title: AmityLocalizedStringSet.Social.pollOptionsTitle.localizedString, description: AmityLocalizedStringSet.Social.pollOptionsDesc.localizedString)
                .padding(.bottom, 20)
            
            ForEach($viewModel.options) { option in
                PollAnswerView(option: option) {
                    let offset = option.index
                    withAnimation {
                        viewModel.removePollOption(at: offset.wrappedValue)
                    }
                }
            }
            
            if viewModel.options.count < maxNoOfOptions {
                Button(action: {
                    withAnimation {
                        let lastIndex = viewModel.options.count
                        viewModel.options.append(PollOption(index: lastIndex))
                    }
                }, label: {
                    HStack {
                        Spacer()
                        
                        Image(systemName: "plus")
                        
                        Text(AmityLocalizedStringSet.Social.pollAddOption.localizedString)
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.secondaryColor)))
                        
                        Spacer()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.secondaryColor))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .border(radius: 8, borderColor: Color(viewConfig.theme.baseColorShade3), borderWidth: 1)
                })
                .padding(.trailing, 32) // Align with poll options textfield
            }
        }
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

struct PollAnswerView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @Binding var option: PollOption
    let onDelete: () -> Void
    let maxCharCount = 60
    
    @State private var mentionData = MentionData()
    @StateObject var viewModel = AmityTextEditorViewModel(mentionManager: MentionManager(withType: .post(communityId: nil)))
    @State private var isCharLimitError = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                
                // 15 + 10 + 10
                AmityMessageTextEditorView(viewModel, text: $option.text, mentionData: $mentionData, mentionedUsers: .constant([]), textViewHeight: 35)
                    .placeholder("\(AmityLocalizedStringSet.Social.pollOptionLabel.localizedString) \(option.index + 1)")
                    .padding([.horizontal], 12)
                    .padding([.vertical], 4)
                    .background(Color(viewConfig.theme.baseColorShade4))
                    .cornerRadius(8, corners: .allCorners)
                    .border(radius: 8, borderColor: .red, borderWidth: isCharLimitError ? 1 : 0)
                    .onChange(of: option.text) { newValue in
                        withAnimation {
                            isCharLimitError = newValue.count > maxCharCount
                        }
                        
                        // Note:
                        // Whenever we delete any poll option, the text value of textfield is not getting updated correctly even when the poll options datasource is correctly updated.
                        // So we forcefully update underlying UITextView in that case.
                        if viewModel.textView.text != newValue {
                            viewModel.textView.text = newValue
                        }
                    }
                
                Button(action: {
                    onDelete()
                }, label: {
                    Image(AmityIcon.trashBinIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                })
            }
            
            if isCharLimitError {
                Text(AmityLocalizedStringSet.Social.pollOptionCharLimitError.localized(arguments: maxCharCount))
                    .applyTextStyle(.caption(Color(viewConfig.theme.alertColor)))
                    .padding(.top, 4)
                    .transition(.opacity)
            }
        }
        .padding(.bottom, 12)
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
