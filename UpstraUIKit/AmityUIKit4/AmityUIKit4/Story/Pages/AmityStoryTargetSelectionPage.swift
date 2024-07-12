//
//  AmityStoryTargetSelectionPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 4/2/24.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityStoryTargetSelectionPage: AmityPageIdentifiable, View {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @Environment(\.colorScheme) private var colorScheme
    
    public var id: PageId {
        .targetSelectionPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    
    public init() {
        _viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .targetSelectionPage))
    }
    
    public var body: some View {
        VStack {
            HStack {
                Image(AmityIcon.closeIcon.getImageResource())
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .padding(.leading, 12)
                    .onTapGesture {
                        if let navigationController = host.controller?.navigationController {
                            navigationController.dismiss(animated: true)
                        } else {
                            host.controller?.dismiss(animated: true)
                        }
                    }
                
                Spacer()
            }
            .overlay(
                Text("Share To")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    
            )
            .frame(height: 58)
            
            TargetSelectionView(communityOnTapAction: { communityModel in
                
                let context = AmityStoryTargetSelectionPageBehaviour.Context(page: self, community: communityModel.object, targetType: .community)
                AmityUIKitManagerInternal.shared.behavior.storyTargetSelectionPageBehaviour?.goToCreateStoryPage(context: context)
                
            })
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
}
