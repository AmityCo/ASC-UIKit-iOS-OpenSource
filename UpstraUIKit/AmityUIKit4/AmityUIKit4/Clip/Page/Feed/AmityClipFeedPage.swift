//
//  ClipFeedPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 18/6/25.
//

import SwiftUI
import AmitySDK

public struct AmityClipFeedPage: AmityPageView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
        
    public var id: PageId {
        return .clipFeedPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject var provider: ClipService
    
    var onTapAction: ((ClipFeedAction) -> Void)?
    
    public init(onTapAction: ((ClipFeedAction) -> Void)? = nil) {
        self._provider = StateObject(wrappedValue: GlobalFeedClipService())
        self.onTapAction = onTapAction
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .clipFeedPage))
    }
    
    public init(provider: ClipService, onTapAction: ((ClipFeedAction) -> Void)? = nil) {
        self._provider = StateObject(wrappedValue: provider)
        self.onTapAction = onTapAction
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .clipFeedPage))
    }
    
    public var body: some View {
        ClipFeedView(clipProvider: provider, onTapAction: onTapAction)
            .updateTheme(with: viewConfig)
    }
}

open class AmityClipFeedPageBehavior {
    
    open class Context {
        public var post: AmityPostModel?
        public var userId: String?
        public var communityId: String?
        
        // Clip Feed contains UICollectionView wrapped in UIViewController
        weak var controller: UIViewController?
        
        public init(controller: UIViewController) {
            self.controller = controller
        }
    }
    
    public init() { }
    
    open func goToPostDetailPage(context: AmityClipFeedPageBehavior.Context) {
        guard let post = context.post else { return }
        
        let postComponentContext = AmityPostContentComponent.Context()
        let vc = AmitySwiftUIHostingController(rootView: AmityPostDetailPage(post: post.object, context: postComponentContext))
        context.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
    open func goToUserProfilePage(context: AmityClipFeedPageBehavior.Context) {
        guard let userId = context.userId else { return }
        let userProfilePage = AmityUserProfilePage(userId: userId)
        let controller = AmitySwiftUIHostingController(rootView: userProfilePage)
        
        context.controller?.navigationController?.pushViewController(controller, animated: true)
    }
    
    open func goToCommunityProfilePage(context: AmityClipFeedPageBehavior.Context) {
        guard let communityId = context.communityId else { return }
        let page = AmityCommunityProfilePage(communityId: communityId)
        let hostController = AmitySwiftUIHostingController(rootView: page)
        context.controller?.navigationController?.pushViewController(hostController, animated: true)
    }
    
    open func goToSelectPostTargetPage(context: AmityClipFeedPageBehavior.Context) {
        let view = AmityPostTargetSelectionPage(context: AmityPostTargetSelectionPage.Context(isClipPost: true))
        let controller = AmitySwiftUIHostingController(rootView: view)
        
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.navigationBar.isHidden = true
        
        context.controller?.present(navigationController, animated: true)
    }
}
