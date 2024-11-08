//
//  PollAnswerResultView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 7/10/2567 BE.
//

import SwiftUI

// Expanded & normal
struct PollAnswerResultView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: PostContentPollViewModel = PostContentPollViewModel()
    
    let answer: AmityPostModel.PollModel.Answer
    let totalVote: Int
    let highestVote: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(answer.text)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        .lineLimit(4)
                    
                    Spacer()
                    
                    let votePercent: Double = totalVote > 0 ? (Double(answer.voteCount) / Double(totalVote)) * 100 : 0
                    let votePercentValue = viewModel.percentageFormatter.string(from: NSNumber(value: votePercent))
                    Text("\(votePercentValue ?? "")%")
                        .applyTextStyle(.bodyBold(Color(answer.voteCount == highestVote && highestVote > 0 ? viewConfig.theme.primaryColor : viewConfig.theme.baseColorShade1)))
                        .lineLimit(1)
                }
                
                HStack {
                    Text(getVoteInfo())
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                    
                    let user = AmityUIKit4Manager.client.user?.snapshot
                    AmityUserProfileImageView(displayName: user?.displayName ?? "", avatarURL: URL(string: user?.getAvatarInfo()?.fileURL ?? ""))
                        .frame(width: 16, height: 16)
                        .clipShape(Circle())
                        .isHidden(!answer.isVotedByUser, remove: true)
                }
                .padding(.top, 4)
                
                PollProgressBarView(value: CGFloat(answer.voteCount), total: CGFloat(totalVote), isHighlighted: answer.voteCount == highestVote && highestVote > 0)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .border(radius: 8, borderColor: Color(answer.voteCount == highestVote && highestVote > 0  ? viewConfig.theme.primaryColor : viewConfig.theme.baseColorShade4 ), borderWidth: 1)
        .contentShape(Rectangle())
    }
    
    func getVoteInfo() -> String {
        guard answer.voteCount > 0 else { return AmityLocalizedStringSet.Social.pollAnswerResultNoVotes.localizedString }
        
        if answer.isVotedByUser && answer.voteCount == 1 {
            return AmityLocalizedStringSet.Social.pollAnswerResultVotedByYou.localizedString
        }
        
        if answer.voteCount > 0 {
            var final = answer.voteCount > 1 ?  AmityLocalizedStringSet.Social.pollAnswerResultVotedByMultipleParticipants.localized(arguments: answer.voteCount.formattedCountString) : AmityLocalizedStringSet.Social.pollAnswerResultVotedBySingleParticipant.localizedString
            final += answer.isVotedByUser ? " " + AmityLocalizedStringSet.Social.pollAnswerResultVotedByAndYou.localizedString : ""
            return final
        }
        
        return ""
    }
}

struct PollProgressBarView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let value: CGFloat
    let total: CGFloat
    let isHighlighted: Bool
    
    var body: some View {
        GeometryReader(content: { geometry in
            Capsule()
                .fill(Color(isHighlighted ? viewConfig.theme.primaryColor.blend(.shade3) : viewConfig.theme.baseColorShade4))
                .overlay(
                    Capsule()
                        .fill(Color(isHighlighted ? viewConfig.theme.primaryColor : viewConfig.theme.baseColorShade1))
                        .frame(height: 8)
                        .frame(width: calculateBarWidth(contentWidth: geometry.size.width))
                    
                    , alignment: .leading)
        })
        .frame(height: 8)
    }
    
    private func calculateBarWidth(contentWidth: CGFloat) -> CGFloat {
        guard total > 0 else { return 0 }
        return (value / total) * contentWidth
    }
}
