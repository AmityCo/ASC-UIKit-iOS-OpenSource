//
//  PollVoteImageOptionSection.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 21/7/25.
//

import SwiftUI

// For both Vote & Result Mode
struct PollVoteImageOptionView: View {
    
    enum Mode {
        case vote
        case result
    }
    
    @EnvironmentObject
    private var viewConfig: AmityViewConfigController
    
    @StateObject
    private var viewModel: PostContentPollViewModel = PostContentPollViewModel()
    
    let mode: Mode
    let answer: AmityPostModel.PollModel.Answer
    let totalVote: Int
    let highestVote: Int
    
    let isSelected: Bool
    let allowMultiSelection: Bool
    let isSelectionDisabled: Bool
    let onSelection: (() -> Void)?
    let onExpand: () -> Void
    
    @State var imageLoadError: Bool = false
    
    var isHighlighted: Bool {
        switch mode {
        case .vote:
            return isSelected
        case .result:
            return answer.voteCount == highestVote && highestVote > 0
        }
    }
    
    var body: some View {
        Button(action: {
            guard mode == .vote && !isSelectionDisabled else { return }
            onSelection?()
        }, label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .top) {
                    AsyncImage(placeholderView: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(viewConfig.theme.baseColorShade4))
                    }, url: URL(string: answer.image?.mediumFileURL ?? ""), contentMode: .fill)
                    .onLoaded({ isLoaded in
                        if !isLoaded {
                            imageLoadError = true
                        }
                    })
                    .frame(height: 108)
                    .cornerRadius(4)
                    .blur(radius: mode == .result ? 0.5 : 0)
                    
                    VStack {
                        Spacer()
                        
                        Image(AmityIcon.pollImageNotAvailableIcon.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                        
                        Spacer()
                    }
                    .visibleWhen(imageLoadError)
                    
                    ZStack {
                        Color.black.opacity(0.3)
                            .cornerRadius(4)
                        
                        let votePercent: Double = totalVote > 0 ? (Double(answer.voteCount) / Double(totalVote)) * 100 : 0
                        let votePercentValue = viewModel.percentageFormatter.string(from: NSNumber(value: votePercent))
                        Text("\(votePercentValue ?? "")%")
                            .applyTextStyle(.headline(Color.white))
                            .lineLimit(1)
                    }
                    .frame(height: 108)
                    .opacity(mode == .result ? 1 : 0)
                    
                    // Top Left
                    imageHeader
                }
                .frame(height: 108)
                
                if !answer.text.isEmpty {
                    Text(answer.text)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        .lineLimit(2)
                        .padding(.top, 12)
                        .disabled(isSelectionDisabled)
                }
                
                if mode == .result {
                    HStack(spacing: 4) {
                        Text(getVoteInfo())
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                        
                        let user = AmityUIKit4Manager.client.user?.snapshot
                        AmityUserProfileImageView(displayName: user?.displayName ?? "", avatarURL: URL(string: user?.getAvatarInfo()?.fileURL ?? ""))
                            .frame(width: 16, height: 16)
                            .clipShape(Circle())
                            .isHidden(!answer.isVotedByUser, remove: true)
                    }
                    .padding(.top, answer.text.isEmpty ? 12 : 4)
                }
                
                Spacer(minLength: 1)
            }
            .padding(12)
            .cornerRadius(16)
            .contentShape(Rectangle())
            .border(radius: 16, borderColor: isHighlighted ? Color(viewConfig.theme.primaryColor) : Color(viewConfig.theme.baseColorShade4), borderWidth: isHighlighted ? 2 : 1)   
        })
        .buttonStyle(.plain)
    }
    
    var imageHeader: some View {
        VStack  {
            HStack {
                Image(allowMultiSelection ? AmityIcon.pollCheckboxIcon.imageResource : AmityIcon.pollRadioIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .opacity(isSelected && mode == .vote ? 1 : 0)
                
                Spacer()
                
                Button(action: {
                    onExpand()
                }, label: {
                    Image(AmityIcon.pollImageExpandIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(4)
                })
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding([.top, .horizontal], 6)
    }
    
    
    func getVoteInfo() -> String {
        guard answer.voteCount > 0 else { return AmityLocalizedStringSet.Social.pollAnswerResultNoVotes.localizedString }
        
        if answer.isVotedByUser && answer.voteCount == 1 {
            return AmityLocalizedStringSet.Social.pollAnswerResultVotedByYou.localizedString
        }
        
        if answer.voteCount > 0 {
            let voteCountExcludingUser = answer.isVotedByUser ? answer.voteCount - 1 : answer.voteCount
            
            var final = voteCountExcludingUser > 1 ? "\(voteCountExcludingUser.formattedCountString) voters" : "1 voter"
            final += answer.isVotedByUser ? " " + AmityLocalizedStringSet.Social.pollAnswerResultVotedByAndYou.localizedString : ""
            return final
        }
        
        return ""
    }
}
