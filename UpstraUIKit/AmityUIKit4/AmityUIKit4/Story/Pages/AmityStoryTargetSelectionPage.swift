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
            let title = viewConfig.getConfig(elementId: .title, key: "text", of: String.self) ?? ""
            let closeButtonIcon = viewConfig.getConfig(elementId: .closeButtonElement, key: "image", of: String.self) ?? ""

            AmityPostTargetSelectionPage.HeaderView(title: title, closeIcon: closeButtonIcon) {
                if let navigationController = host.controller?.navigationController {
                    navigationController.dismiss(animated: true)
                } else {
                    host.controller?.dismiss(animated: true)
                }
            }
            
            TargetSelectionView(communityOnTapAction: { communityModel in
                
                let context = AmityStoryTargetSelectionPageBehaviour.Context(page: self, community: communityModel.object, targetType: .community)
                AmityUIKitManagerInternal.shared.behavior.storyTargetSelectionPageBehaviour?.goToCreateStoryPage(context: context)
                
            }, contentType: .story)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
}
