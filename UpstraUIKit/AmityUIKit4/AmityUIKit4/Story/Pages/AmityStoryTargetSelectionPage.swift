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
        .storyTargetSelectionPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    
    public init() {
        _viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .storyTargetSelectionPage))
    }
    
    public var body: some View {
        VStack {
            HStack {
                let closeButtonIcon = viewConfig.getConfig(elementId: .closeButtonElement, key: "image", of: String.self) ?? ""
                Image(AmityIcon.getImageResource(named: closeButtonIcon))
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
                Text(viewConfig.getConfig(elementId: .title, key: "text", of: String.self) ?? "")
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
            )
            .frame(height: 58)
            
            TargetSelectionView(communityOnTapAction: { communityModel in
                
                let context = AmityStoryTargetSelectionPageBehaviour.Context(page: self, community: communityModel.object, targetType: .community)
                AmityUIKitManagerInternal.shared.behavior.storyTargetSelectionPageBehaviour?.goToCreateStoryPage(context: context)
                
            }, contentType: .story)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
}
