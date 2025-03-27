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
    private let mytimelineAvatarURL: URL? = URL(string: AmityUIKitManagerInternal.shared.client.user?.snapshot?.getAvatarInfo()?.fileURL ?? "")
    
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
            
            AmityNavigationBar(title: navTitle) {
                let closeButton = viewConfig.getConfig(elementId: .closeButtonElement, key: "image", of: String.self) ?? ""
                Image(AmityIcon.getImageResource(named: closeButton))
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .onTapGesture {
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
            } trailing: {
                EmptyView()
            }
            
            TargetSelectionView(headerView: {
                VStack(spacing: 10) {
                    HStack(spacing: 0) {
                        AsyncImage(placeholder: AmityIcon.defaultCommunityAvatar.getImageResource(), url: mytimelineAvatarURL)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 12))
                            .isHidden(viewConfig.isHidden(elementId: .myTimelineAvatar), remove: true)
                            .accessibilityIdentifier(AccessibilityID.Social.PostTargetSelection.myTimelineAvatar)
                            
                        let myTimelineTitle = viewConfig.getConfig(elementId: .myTimelineText, key: "text", of: String.self) ?? ""
                        Text(myTimelineTitle)
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                            .isHidden(viewConfig.isHidden(elementId: .myTimelineText), remove: true)
                            .accessibilityIdentifier(AccessibilityID.Social.PostTargetSelection.myTimelineText)
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleSelection(communityModel: nil)
                    }
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 1)
                }
                .padding([.leading, .trailing], 16)
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

#Preview {
    AmityLivestreamPostTargetSelectionPage()
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
