//
//  PollTextOptionSection.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 18/7/25.
//
import SwiftUI

struct PollTextOptionSection: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @ObservedObject var viewModel: PollPostComposerViewModel
    
    private let maxNoOfOptions = 10
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            PollSectionHeader(title: AmityLocalizedStringSet.Social.pollOptionsTitle.localizedString, description: AmityLocalizedStringSet.Social.pollOptionsDesc.localizedString)
                .padding(.bottom, 20)
            
            ForEach($viewModel.textOptions) { option in
                PollTextOptionView(option: option) {
                    let offset = option.index
                    withAnimation {
                        viewModel.removeTextOption(at: offset.wrappedValue)
                    }
                }
            }
            
            if viewModel.textOptions.count < maxNoOfOptions {
                Button(action: {
                    withAnimation {
                        let lastIndex = viewModel.textOptions.count
                        viewModel.textOptions.append(PollOption(index: lastIndex))
                    }
                }, label: {
                    HStack {
                        Spacer()
                        
                        Image(systemName: "plus")
                        
                        Text(AmityLocalizedStringSet.Social.pollAddOption.localizedString)
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        
                        Spacer()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .border(radius: 8, borderColor: Color(viewConfig.theme.baseColorShade3), borderWidth: 1)
                })
                .padding(.trailing, 32) // Align with poll options textfield
            }
        }
    }
}

struct PollTextOptionView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @Binding var option: PollOption
    let onDelete: () -> Void
    let maxCharCount = 60
    
    @State private var mentionData = MentionData()
    @StateObject var viewModel = AmityTextEditorViewModel(mentionManager: MentionManager(withType: .post(communityId: nil)))
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                
                // 15 + 10 + 10
                AmityMessageTextEditorView(viewModel, text: $option.text, mentionData: $mentionData, mentionedUsers: .constant([]), textViewHeight: 35)
                    .placeholder("\(AmityLocalizedStringSet.Social.pollOptionLabel.localizedString) \(option.index + 1)")
                    .characterLimit(maxCharCount)
                    .padding([.horizontal], 12)
                    .padding([.vertical], 4)
                    .background(Color(viewConfig.theme.baseColorShade4))
                    .cornerRadius(8, corners: .allCorners)
                    .onChange(of: option.text) { newValue in
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
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                    
                })
            }
        }
        .padding(.bottom, 12)
    }
}
