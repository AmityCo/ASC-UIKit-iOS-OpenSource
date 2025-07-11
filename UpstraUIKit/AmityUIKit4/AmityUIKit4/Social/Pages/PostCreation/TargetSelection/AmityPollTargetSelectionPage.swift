//
//  AmityPollTargetSelectionPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 16/10/2567 BE.
//

import SwiftUI

public struct AmityPollTargetSelectionPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .pollTargetSelectionPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    
    public init() {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .postTargetSelectionPage))
    }
    
    public var body: some View {
        VStack {
            let navTitle = viewConfig.getConfig(elementId: .title, key: "text", of: String.self) ?? ""
            let closeIcon = viewConfig.getConfig(elementId: .closeButtonElement, key: "image", of: String.self) ?? ""
            AmityPostTargetSelectionPage.HeaderView(title: navTitle, closeIcon: closeIcon) {
                if let navigationController = host.controller?.navigationController {
                    navigationController.dismiss(animated: true)
                } else {
                    host.controller?.dismiss(animated: true)
                }
            }
            
            TargetSelectionView(headerView: {
                AmityPostTargetSelectionPage.MyTimelineView {
                    let context = AmityPollTargetSelectionPageBehavior.Context(page: self, community: nil)
                    AmityUIKitManagerInternal.shared.behavior.pollTargetSelectionPageBehavior?.goToPollPostComposerPage(context: context)
                }
            }, communityOnTapAction: { communityModel in
                let context = AmityPollTargetSelectionPageBehavior.Context(page: self, community: communityModel)
                AmityUIKitManagerInternal.shared.behavior.pollTargetSelectionPageBehavior?.goToPollPostComposerPage(context: context)

            }, contentType: .post)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
}

open class AmityPollTargetSelectionPageBehavior {
    
    open class Context {
        public let page: AmityPollTargetSelectionPage
        public let community: AmityCommunityModel?
        
        init(page: AmityPollTargetSelectionPage, community: AmityCommunityModel?) {
            self.page = page
            self.community = community
        }
    }
    
    public init() {}
    
    open func goToPollPostComposerPage(context: AmityPollTargetSelectionPageBehavior.Context) {
        
        let view: AmityPollPostComposerPage
        if let community = context.community {
            view = AmityPollPostComposerPage(targetId: community.communityId, targetType: .community)
        } else {
            view = AmityPollPostComposerPage(targetId: nil, targetType: .user)
        }
        
        let controller = AmitySwiftUIHostingController(rootView: view)
        context.page.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
}
