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
    
    @State private var showPollSelectionView = false
    @State private var communityModel: AmityCommunityModel?
    
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
                    showPollSelectionView.toggle()
                }
            }, communityOnTapAction: { communityModel in
                self.communityModel = communityModel
                showPollSelectionView.toggle()
            }, contentType: .post)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .bottomSheet(isShowing: $showPollSelectionView, height: .contentSize, sheetContent: {
            PollTypeSelectionView(onNextAction: { pollType in
                
                showPollSelectionView = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if let communityModel {
                        let context = AmityPollTargetSelectionPageBehavior.Context(page: self, community: communityModel, pollType: pollType)
                        AmityUIKitManagerInternal.shared.behavior.pollTargetSelectionPageBehavior?.goToPollPostComposerPage(context: context)
                    } else {
                        let context = AmityPollTargetSelectionPageBehavior.Context(page: self, community: nil, pollType: pollType)
                        AmityUIKitManagerInternal.shared.behavior.pollTargetSelectionPageBehavior?.goToPollPostComposerPage(context: context)
                    }
                }
            })
            .environmentObject(viewConfig)
        })
        .updateTheme(with: viewConfig)
    }
}

open class AmityPollTargetSelectionPageBehavior {
    
    open class Context {
        public let page: AmityPollTargetSelectionPage
        public let community: AmityCommunityModel?
        public let pollType: AmityPollType
        
        init(page: AmityPollTargetSelectionPage, community: AmityCommunityModel?, pollType: AmityPollType) {
            self.page = page
            self.community = community
            self.pollType = pollType
        }
    }
    
    public init() {}
    
    open func goToPollPostComposerPage(context: AmityPollTargetSelectionPageBehavior.Context) {
        
        let view: AmityPollPostComposerPage
        if let community = context.community {
            view = AmityPollPostComposerPage(targetId: community.communityId, targetType: .community, pollType: context.pollType)
        } else {
            view = AmityPollPostComposerPage(targetId: nil, targetType: .user, pollType: context.pollType)
        }
        
        let controller = AmitySwiftUIHostingController(rootView: view)
        context.page.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
}
