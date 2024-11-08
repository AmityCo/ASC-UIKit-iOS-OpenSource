//
//  PostContentPollView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 9/10/2567 BE.
//

import SwiftUI

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
                    .isHidden(showResultsForOwner, remove: true)
                
                // Show only 4 options in feed and show all options in post detail page.
                if poll.isVoted || poll.isClosed || showResultsForOwner {
                    // Results
                    let sortedAnswers = poll.answers.sorted { $0.voteCount >= $1.voteCount }
                    let options = style == .feed ? Array(sortedAnswers.prefix(4)) : sortedAnswers
                    let highestVote = sortedAnswers.first?.voteCount ?? 0
                    ForEach(options) { answer in
                        PollAnswerResultView(answer: answer, totalVote: poll.voteCount, highestVote: highestVote)
                    }
                    .transition(.opacity.combined(with: .scale))
                } else {
                    // Options to Vote
                    let options = style == .feed && !isInPendingFeed ? Array(poll.answers.prefix(4)) : poll.answers
                    ForEach(options) { answer in
                        
                        let isCommunityJoined = post.targetCommunity?.isJoined ?? true
                        let isPollSelectionDisabled = isInPendingFeed || !isCommunityJoined
                        PollOptionView(title: answer.text, isSelected: selectedAnswers.contains(answer.id), allowMultiSelection: poll.canVoteMultipleOptions, onSelection: {
                            guard !poll.isVoted || !poll.isClosed else { return }
                            
                            selectAnswer(answer: answer)
                        })
                        .disabled(isPollSelectionDisabled)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
                
                // Navigate to post detail page
                Button(action: {
                    action(.viewDetail)
                }, label: {
                    HStack {
                        Spacer()
                                            
                        Text(poll.isVoted || poll.isClosed ? AmityLocalizedStringSet.Social.pollSeeFullResultsLabel.localizedString : AmityLocalizedStringSet.Social.pollSeeMoreOptionsLabel.localized(arguments: poll.answers.count - 4))
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.secondaryColor)))
                                
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    .border(radius: 8, borderColor: Color(viewConfig.theme.baseColorShade3), borderWidth: 1)
                })
                .isHidden(style == .detail || poll.answers.count < 5 || isInPendingFeed, remove: true)
                
                // Vote Poll
                Button(action: {
                    guard !selectedAnswers.isEmpty else { return }
                    
                    viewModel.vote(poll: poll, answers: Array(selectedAnswers))
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
                .isHidden(poll.isClosed || poll.isVoted || showResultsForOwner, remove: true)
                
                HStack {
                    Group {
                        // Number of votes
                        let formattedVoteCount = viewModel.voteCountFormatter.string(from: NSNumber(value: poll.voteCount)) ?? ""
                        Text(AmityLocalizedStringSet.Social.pollVoteCounts.localized(arguments: formattedVoteCount))
                            .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade2)))
                        
                        Text("•")
                            .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade2)))
                        
                        // Days Remaining or Ended
                        let pollStatus = PollStatus(poll: poll)
                        Text(pollStatus.statusInfo)
                            .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade2)))
                    }
                    
                    Spacer()
                    
                    // Action button for poll owner. Only owner of the post can see this
                    let isResultsButtonVisible = post.isOwner && !poll.isClosed && !poll.isVoted && !isInPendingFeed
                    Button {
                        
                        if style == .feed {
                            action(.viewDetailWithResults)
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
                    
                }
                .padding(.top, 4)
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
}

class PostContentPollViewModel: ObservableObject {
    
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
                print("Error while voting poll \(error)")
            }
        }
    }
}

