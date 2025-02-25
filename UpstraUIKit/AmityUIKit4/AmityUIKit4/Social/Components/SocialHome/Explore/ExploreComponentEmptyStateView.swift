//
//  ExploreComponentEmptyStateView.swift
//  AmityUIKit4
//
//  Created by Nishan on 29/8/2567 BE.
//

import SwiftUI

struct ExploreComponentEmptyStateView: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    enum StateType {
        case unableToLoad
        case communitiesNotAvailable
    }
    
    let emptyStateType: StateType
    let action: DefaultTapAction?
    
    init(type: StateType, action: DefaultTapAction?) {
        self.emptyStateType = type
        self.action = action
    }
    
    var body: some View {
        
        if emptyStateType == .unableToLoad {
            AmityEmptyStateView(configuration: .init(image: AmityIcon.emptyStateExplore.rawValue, title: "Something went wrong", subtitle: "Please try again", iconSize: CGSize(width: 80, height: 80), renderingMode: .original, tapAction: nil))
        } else {
            VStack(alignment: .center, spacing: 0) {
                // emptyNewsFeedIcon
                Image(AmityIcon.emptyNewsFeedIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    
                Text("No community yet")
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade2)))
                    .padding(.top, 24)
                
                Text("Let's create your own communities")
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade2)))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                
                Button {
                    ImpactFeedbackGenerator.impactFeedback(style: .medium)
                    
                    action?()
                } label: {
                    HStack(spacing: 0) {
                        Image(AmityIcon.plusIcon.imageResource)
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color(.white))
                        
                        Text("Create Community")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(.white))
                            .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(height: 40)
                .background(Color(viewConfig.theme.primaryColor))
                .cornerRadius(8, corners: .allCorners)
                .padding(.top, 16)
            }
        }
    }
}

#if DEBUG
#Preview {
    ExploreComponentEmptyStateView(type: .unableToLoad, action: nil)
        .environmentObject(AmityViewConfigController(pageId: .socialHomePage))
}
#endif
