//
//  AmityLivestreamPostTargetSelectionPageBehavior.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 3/3/25.
//

import SwiftUI
import AmitySDK

open class AmityLivestreamPostTargetSelectionPageBehavior {
    
    open class Context {
        public let page: AmityLivestreamPostTargetSelectionPage
        public let community: AmityCommunityModel?
        
        init(page: AmityLivestreamPostTargetSelectionPage, community: AmityCommunityModel?) {
            self.page = page
            self.community = community
        }
    }
    
    public init() {}
    
    open func goToLiveStreamComposerPage(context: AmityLivestreamPostTargetSelectionPageBehavior.Context) {
        let targetType: AmityPostTargetType = context.community == nil ? .user : .community
        let targetId = targetType == .community ? context.community?.communityId ?? "" : AmityUIKitManagerInternal.shared.currentUserId
        let view = AmityCreateLivestreamPage(targetId: targetId, targetType: targetType)
        
        let controller = AmitySwiftUIHostingController(rootView: view)
        controller.modalPresentationStyle = .fullScreen
        context.page.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
    
}
