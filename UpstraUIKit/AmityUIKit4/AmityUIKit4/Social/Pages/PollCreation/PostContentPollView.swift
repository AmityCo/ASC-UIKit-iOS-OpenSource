//
//  PostContentPollView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 9/10/2567 BE.
//

import SwiftUI
import AmitySDK

enum PollAction {
    case viewDetail
    case viewDetailWithResults
}

struct PostContentPollView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: PostContentPollViewModel = PostContentPollViewModel()
    
    private let style: AmityPostContentComponentStyle
    private let post: AmityPostModel
    private let poll: AmityPostModel.PollModel?
    private let action: (PollAction) -> ()
    private let isInPendingFeed: Bool
    
    @State private var selectedAnswers: Set<String> = []
    @State private var showResultsForOwner = false
    @State private var showMediaViewer = false
    
    @State private var isPollOptionExpanded = false
    let minimumVisibleAnswersCount: Int = 4
    let maximumVisibleAnswersCount: Int = 10
    
    // Image Poll
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init(style: AmityPostContentComponentStyle,
         post: AmityPostModel,
         showPollResults: Bool = false,
         isInPendingFeed: Bool = false,
         action: @escaping (PollAction) -> ()) {
        self.style = style
        self.post = post
        self.action = action
        self.isInPendingFeed = isInPendingFeed
        self._showResultsForOwner = State(initialValue: showPollResults)
        self.poll = post.poll
    }
    
    var body: some View {
        if let poll = post.poll {
            VStack(alignment: .leading, spacing: 12) {
                
                Text(poll.canVoteMultipleOptions ? AmityLocalizedStringSet.Social.pollSelectOneOrMoreOptionLabel.localizedString : AmityLocalizedStringSet.Social.pollSelectOneOptionLabel.localizedString)
                    .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade2)))
                    .isHidden(showResultsForOwner || poll.isVoted, remove: true)
                
                // Show only 4 options in feed and show all options in post detail page.
                if poll.isVoted || poll.isClosed || showResultsForOwner || viewModel.isPollClosedOnServer {
                    // Results
                    let sortedAnswers = poll.answers.sorted { $0.voteCount > $1.voteCount }
                    let prefixLimit = isPollOptionExpanded ? maximumVisibleAnswersCount : minimumVisibleAnswersCount
                    let options = style == .feed ? Array(sortedAnswers.prefix(prefixLimit)) : sortedAnswers
                    let highestVote = sortedAnswers.first?.voteCount ?? 0
                    
                    if poll.isImagePoll {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(options, id: \.id) { answer in
                                PollVoteImageOptionView(mode: .result, answer: answer, totalVote: poll.voteCount, highestVote: highestVote, isSelected: selectedAnswers.contains(answer.id), allowMultiSelection: poll.canVoteMultipleOptions, isSelectionDisabled: isInPendingFeed, onSelection: nil) {
                                    openImageInMediaViewer(answer: answer)
                                }
                            }
                        }
//                        .transition(.opacity.combined(with: .scale))
                    } else {
                        ForEach(options) { answer in
                            PollAnswerResultView(answer: answer, totalVote: poll.voteCount, highestVote: highestVote)
                        }
//                        .transition(.opacity.combined(with: .scale))
                    }
                } else {
                    // Options to Vote
                    let prefixLimit = isPollOptionExpanded ? maximumVisibleAnswersCount : minimumVisibleAnswersCount
                    let options = style == .feed && !isInPendingFeed ? Array(poll.answers.prefix(prefixLimit)) : poll.answers
                    
                    if poll.isImagePoll {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(options, id: \.id) { answer in
                                let isCommunityJoined = post.targetCommunity?.isJoined ?? true
                                let isPollSelectionDisabled = isInPendingFeed || !isCommunityJoined
                                PollVoteImageOptionView(mode: .vote, answer: answer, totalVote: 0, highestVote: 0, isSelected: selectedAnswers.contains(answer.id), allowMultiSelection: poll.canVoteMultipleOptions, isSelectionDisabled: isPollSelectionDisabled) {
                                    
                                    guard !poll.isVoted || !poll.isClosed else { return }
                                    
                                    selectAnswer(answer: answer)
                                } onExpand: {
                                    openImageInMediaViewer(answer: answer)
                                }
                            }
                        }
//                        .transition(.opacity.combined(with: .scale))
                    } else {
                        ForEach(options) { answer in
                            
                            let isCommunityJoined = post.targetCommunity?.isJoined ?? true
                            let isPollSelectionDisabled = isInPendingFeed || !isCommunityJoined
                            PollVoteTextOptionView(title: answer.text, isSelected: selectedAnswers.contains(answer.id), allowMultiSelection: poll.canVoteMultipleOptions, onSelection: {
                                guard !poll.isVoted || !poll.isClosed else { return }
                                
                                selectAnswer(answer: answer)
                            })
                        }
//                        .transition(.opacity.combined(with: .scale))
                    }
                }
                
                // See more poll options | see more results
                Button(action: {
                    withAnimation {
                        isPollOptionExpanded = true
                    }
                }, label: {
                    HStack {
                        Spacer()
                        
                        // showResultsForOwner
                        Text(poll.isVoted || poll.isClosed || viewModel.isPollClosedOnServer || (showResultsForOwner && !isPollOptionExpanded) ? AmityLocalizedStringSet.Social.pollSeeFullResultsLabel.localizedString : AmityLocalizedStringSet.Social.pollSeeMoreOptionsLabel.localized(arguments: poll.answers.count - minimumVisibleAnswersCount))
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.secondaryColor)))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    .border(radius: 8, borderColor: Color(viewConfig.theme.baseColorShade3), borderWidth: 1)
                })
                .isHidden(style == .detail || poll.answers.count <= minimumVisibleAnswersCount || isInPendingFeed || isPollOptionExpanded, remove: true)
                
                // Vote Poll
                Button(action: {
                    AmityUserAction.perform {
                        guard !selectedAnswers.isEmpty else { return }
                        
                        // If user is member
                        let isCommunityJoined = post.targetCommunity?.isJoined ?? true
                        if !isCommunityJoined {
                            AmityUIKit4Manager.behaviour.globalBehavior?.handleNonMemberAction(context: nil)
                            return
                        }

                        viewModel.vote(poll: poll, answers: Array(selectedAnswers))
                    }
                }, label: {
                    HStack {
                        Spacer()
                        
                        Text(AmityLocalizedStringSet.Social.pollVoteButton.localizedString)
                            .applyTextStyle(.bodyBold(.white))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(selectedAnswers.isEmpty ? Color(viewConfig.theme.primaryColor.blend(.shade2)) : Color(viewConfig.theme.primaryColor))
                    .contentShape(Rectangle())
                    .cornerRadius(8, corners: .allCorners)
                })
                .buttonStyle(.plain)
                .isHidden(poll.isClosed || viewModel.isPollClosedOnServer || poll.isVoted || showResultsForOwner, remove: true)
                
                HStack {
                    Group {
                        // Number of votes
                        let formattedVoteCount = viewModel.voteCountFormatter.string(from: NSNumber(value: poll.voteCount)) ?? ""
                        Text(AmityLocalizedStringSet.Social.pollVoteCounts.localized(arguments: formattedVoteCount))
                            .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade2)))
                        
                        Text("•")
                            .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade2)))
                        
                        // Days Remaining or Ended
                        let pollStatus = PollStatus(poll: poll, isInPendingFeed: isInPendingFeed)
                        let statusInfo = viewModel.isPollClosedOnServer ? AmityLocalizedStringSet.Social.pollStatusEnded.localizedString : pollStatus.statusInfo
                        Text(statusInfo)
                            .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade2)))
                    }
                    
                    Spacer()
                    
                    // Action button for poll owner. Only owner of the post can see this
                    let isResultsButtonVisible = post.isOwner && !poll.isClosed && !poll.isVoted && !isInPendingFeed
                    Button {
                        
                        if style == .feed {
                            withAnimation {
                                showResultsForOwner.toggle()
                            }
                            
                            return
                        }
                        
                        if style == .detail {
                            withAnimation {
                                showResultsForOwner.toggle()
                            }
                        }
                        
                    } label: {
                        Text(showResultsForOwner ? AmityLocalizedStringSet.Social.pollBackToVoteLabel.localizedString : AmityLocalizedStringSet.Social.pollSeeResultsLabel.localizedString)
                            .applyTextStyle(.captionBold(Color(viewConfig.theme.primaryColor)))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isResultsButtonVisible)
                    .isHidden(!isResultsButtonVisible, remove: false)
                    
                    let isUnvoteButtonVisible = poll.isVoted && !poll.isClosed && !viewModel.isPollClosedOnServer && !isInPendingFeed
                    Button {
                        selectedAnswers.removeAll()
                        viewModel.unVote(poll: poll)
                    } label: {
                        Text(AmityLocalizedStringSet.Social.pollUnvoteButton.localizedString)
                            .applyTextStyle(.captionBold(Color(viewConfig.theme.primaryColor)))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isUnvoteButtonVisible)
                    .isHidden(!isUnvoteButtonVisible, remove: true)
                }
                .padding(.top, 4)
            }
            .fullScreenCover(isPresented: $showMediaViewer) {
                MediaViewer(
                    medias: viewModel.getSelectedMedia(),
                    startIndex: 0,
                    viewConfig: viewConfig,
                    closeAction: {
                        showMediaViewer.toggle()
                    },
                    showEditAction: post.isOwner,
                    post: post,
                    showViewParentPost: false
                )
            }
            
        } else {
            // Poll post should always contain poll, so this block might never be reached.
            EmptyView()
        }
    }
    
    // MARK: Functionality
    
    func selectAnswer(answer: AmityPostModel.PollModel.Answer) {
        guard let poll else { return }
        if poll.canVoteMultipleOptions {
            if selectedAnswers.contains(answer.id) {
                selectedAnswers.remove(answer.id)
            } else {
                selectedAnswers.insert(answer.id)
            }
        } else {
            selectedAnswers.removeAll()
            selectedAnswers.insert(answer.id)
        }
    }
    
    func openImageInMediaViewer(answer: AmityPostModel.PollModel.Answer) {
        guard let image = answer.image else { return }
        
        viewModel.expandedImage = image
        showMediaViewer = true
    }
}

class PostContentPollViewModel: ObservableObject {
    
    var expandedImage: AmityImageData?
    
    lazy var percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    lazy var voteCountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        return formatter
    }()
    
    let pollManager = PollManager()
    
    // When user tries to vote or unvote and the poll has already ended,
    // we receive 400000 error code. This property tracks poll status
    // upon receiving the error.
    @Published var isPollClosedOnServer = false
    
    @MainActor
    func vote(poll: AmityPostModel.PollModel, answers: [String]) {
        Task {
            do {
                let _ = try await pollManager.votePoll(pollId: poll.id, answerIds: answers)
                
                // Post notification
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: .didVotePoll, object: nil)
                }
            } catch let error {
                if error.isErrorCode(400000) {
                    self.isPollClosedOnServer = true
                    Toast.showToast(style: .warning, message: "Poll ended.")
                } else if error.isErrorCode(400400) {
                    Toast.showToast(style: .warning, message: "This post is no longer available.")
                } else {
                    Toast.showToast(style: .warning, message: "Oops, something went wrong.")
                }
                
                Log.add(event: .error, "Error while voting poll \(error)")
            }
        }
    }
    
    
    func unVote(poll: AmityPostModel.PollModel) {
        Task.runOnMainActor { [weak self] in
            do {
                let _ = try await self?.pollManager.unvotePoll(pollId: poll.id)
                Toast.showToast(style: .success, message: "Vote removed.")
                
                // Post notification
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: .didVotePoll, object: nil)
                }
            } catch let error {
                if error.isErrorCode(400000) {
                    self?.isPollClosedOnServer = true
                    Toast.showToast(style: .warning, message: "Poll ended.")
                } else if error.isErrorCode(400400) {
                    Toast.showToast(style: .warning, message: "This post is no longer available.")
                } else {
                    Toast.showToast(style: .warning, message: "Oops, something went wrong.")
                }
                
                Log.add(event: .error, "Error while voting poll \(error)")
            }
        }
    }
    
    func getSelectedMedia() -> [AmityMedia] {
        guard let expandedImage else {
            Log.add(event: .error, "No image data found to expand")
            return []
        }
        
        let state = AmityMediaState.downloadableImage(imageData: expandedImage, placeholder: UIImage())
        
        let media = AmityMedia(state: state, type: .image)
        media.image = expandedImage
        
        return [media]
    }
}

fileprivate extension Error {
    
    func isErrorCode(_ code: Int) -> Bool {
        let errorCode = (self as NSError).code
        return errorCode == code
    }
}
