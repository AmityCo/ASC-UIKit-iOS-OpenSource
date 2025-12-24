//
//  AmityEventTargetSelectionPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 10/10/25.
//

import SwiftUI

public struct AmityEventTargetSelectionPage: AmityPageView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    
    @StateObject var viewModel = TargetSelectionViewModel(contentType: .post)
    
    public var id: PageId {
        return .eventTargetSelectionPage
    }
    
    public init() {
        _viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .eventTargetSelectionPage))
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
            
            if viewModel.communities.isEmpty {
                VStack {
                    Spacer()

                    AmityEmptyStateView(configuration: .init(image: AmityIcon.emptyNewsFeedIcon.rawValue, title: AmityLocalizedStringSet.Social.eventTargetSelectionNoCommunities.localizedString, subtitle: nil, iconSize: .init(width: 160, height: 160), renderingMode: .original, imageBottomPadding: 0, tapAction: nil))

                    Spacer()
                }
            } else {
                TargetSelectionView(communityOnTapAction: { communityModel in
                    let context = AmityEventTargetSelectionPageBehavior.Context(page: self, community: communityModel)
                    AmityUIKitManagerInternal.shared.behavior.eventTargetSelectionPageBehavior?.goToEventSetupPage(context: context)
                    
                }, contentType: .post, viewModel: viewModel)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
}

open class AmityEventTargetSelectionPageBehavior {
    
    open class Context {
        public let page: AmityEventTargetSelectionPage
        public let community: AmityCommunityModel?
        
        public init(page: AmityEventTargetSelectionPage, community: AmityCommunityModel?) {
            self.page = page
            self.community = community
        }
    }
    
    public init() { }
    
    open func goToEventSetupPage(context: Context) {
        guard let community = context.community else { return }
        
        let createEventPage = AmityEventSetupPage(mode: .create(targetId: community.communityId, targetName: community.displayName))
        let controller = AmitySwiftUIHostingController(rootView: createEventPage)
        
        context.page.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
}
