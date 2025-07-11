//
//  AmityPostTargetSelectionPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/7/24.
//

import SwiftUI

public struct AmityPostTargetSelectionPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .postTargetSelectionPage
    }
    
    @StateObject
    private var viewConfig: AmityViewConfigController
    
    private var context: AmityPostTargetSelectionPage.Context?
    
    public init() {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .postTargetSelectionPage))
    }
    
    public init(context: AmityPostTargetSelectionPage.Context) {
        self.context = context
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .postTargetSelectionPage))
    }
    
    public var body: some View {
        VStack {
            let closeButton = viewConfig.getConfig(elementId: .closeButtonElement, key: "image", of: String.self) ?? ""
            HeaderView(title: viewConfig.getConfig(elementId: .title, key: "text", of: String.self) ?? "", closeIcon: closeButton) {
                if let navigationController = host.controller?.navigationController {
                    navigationController.dismiss(animated: true)
                } else {
                    host.controller?.dismiss(animated: true)
                }
            }
            
            TargetSelectionView(headerView: {
                MyTimelineView {
                    handleTargetSelection(community: nil)
                }
            }, communityOnTapAction: { communityModel in
                handleTargetSelection(community: communityModel)
            }, contentType: .post)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    func handleTargetSelection(community: AmityCommunityModel?) {
        let behaviorContext = AmityPostTargetSelectionPageBehavior.Context(page: self, community: community)

        if let context, context.isClipPost {
            AmityUIKitManagerInternal.shared.behavior.postTargetSelectionPageBehavior?.goToClipComposerPage(context: behaviorContext)
        } else {
            AmityUIKitManagerInternal.shared.behavior.postTargetSelectionPageBehavior?.goToPostComposerPage(context: behaviorContext)
        }
    }
    
    struct MyTimelineView: View {
        
        @EnvironmentObject var viewConfig: AmityViewConfigController
        
        let onSelection: DefaultTapAction
        
        private let mytimelineAvatarURL: URL? = URL(string: AmityUIKitManagerInternal.shared.client.user?.snapshot?.getAvatarInfo()?.fileURL ?? "")

        var body: some View {
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
                    onSelection()
                }
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
            }
            .padding([.leading, .trailing], 16)
        }
    }

    struct HeaderView: View {
        
        @EnvironmentObject var viewConfig: AmityViewConfigController
        
        let title: String
        let closeIcon: String
        let closeAction: DefaultTapAction
        
        var body: some View {
            AmityNavigationBar(title: title) {
                Image(AmityIcon.getImageResource(named: closeIcon))
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .onTapGesture {
                        closeAction()
                    }
            } trailing: {
                EmptyView()
            }
        }
    }
}

extension AmityPostTargetSelectionPage {
    
    public class Context {
        
        let isClipPost: Bool
        
        init(isClipPost: Bool) {
            self.isClipPost = isClipPost
        }
    }
}
