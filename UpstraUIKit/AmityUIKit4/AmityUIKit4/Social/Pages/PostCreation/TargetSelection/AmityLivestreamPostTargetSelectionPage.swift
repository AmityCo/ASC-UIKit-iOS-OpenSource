//
//  AmityLivestreamPostTargetSelectionPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 3/3/25.
//

import SwiftUI

public struct AmityLivestreamPostTargetSelectionPage: AmityPageView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    private var context: AmityLivestreamPostTargetSelectionPage.Context?
    
    public var id: PageId {
        .liveStreamTargetSelectionPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    
    public init() {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .liveStreamTargetSelectionPage))
    }
    
    public init(context: AmityLivestreamPostTargetSelectionPage.Context) {
        self.context = context
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .liveStreamTargetSelectionPage))
    }
    
    public var body: some View {
        VStack {
            let navTitle = viewConfig.getConfig(elementId: .title, key: "text", of: String.self) ?? "Live on"
            let closeButton = viewConfig.getConfig(elementId: .closeButtonElement, key: "image", of: String.self) ?? ""
                        
            AmityPostTargetSelectionPage.HeaderView(title: navTitle, closeIcon: closeButton) {
                if let context, context.isOpenedFromLiveStreamPage {
                    host.controller?.dismiss(animated: true)
                    return
                }
                
                if let navigationController = host.controller?.navigationController {
                    navigationController.dismiss(animated: true)
                } else {
                    host.controller?.dismiss(animated: true)
                }
            }
            
            TargetSelectionView(headerView: {
                AmityPostTargetSelectionPage.MyTimelineView {
                    handleSelection(communityModel: nil)
                }
            }, communityOnTapAction: { communityModel in
                handleSelection(communityModel: communityModel)
            }, contentType: .post)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    func handleSelection(communityModel: AmityCommunityModel?) {
        if let context {
            context.onSelection?(communityModel)
            
            // Dismiss this page
            host.controller?.dismiss(animated: true)
            
            return
        }
        
        let context = AmityLivestreamPostTargetSelectionPageBehavior.Context(page: self, community: communityModel)
        AmityUIKitManagerInternal.shared.behavior.liveStreamPostTargetSelectionPageBehavior?.goToLiveStreamComposerPage(context: context)
    }
}

extension AmityLivestreamPostTargetSelectionPage {
    
    public class Context {
        /// Overrides default behavior of target selection.
        var onSelection: ((AmityCommunityModel?) -> Void)?
        
        /// Whether this target selection page is opened from live stream page
        var isOpenedFromLiveStreamPage: Bool
        
        public init(onSelection: ((AmityCommunityModel?) -> Void)?, isOpenedFromLiveStreamPage: Bool) {
            self.onSelection = onSelection
            self.isOpenedFromLiveStreamPage = isOpenedFromLiveStreamPage
        }
    }
}
