//
//  AmityPostTargetSelectionPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/7/24.
//

import SwiftUI

public struct AmityPostTargetSelectionPage: AmityPageView {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .postTargetSelectionPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    private let mytimelineAvatarURL: URL? = URL(string: AmityUIKitManagerInternal.shared.client.user?.snapshot?.getAvatarInfo()?.fileURL ?? "")
    
    public init() {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .postTargetSelectionPage))
    }
    
    public var body: some View {
        VStack {
            HStack {
                Image(AmityIcon.closeIcon.getImageResource())
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
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
                Text("Post To")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    
            )
            .padding([.leading, .trailing], 12)
            .frame(height: 58)

            
            TargetSelectionView(headerView: {
                VStack(spacing: 10) {
                    HStack(spacing: 0) {
                        AsyncImage(placeholder: AmityIcon.defaultCommunityAvatar.getImageResource(), url: mytimelineAvatarURL)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 12))
                            
                        
                        Text("My Timeline")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let createOptions = AmityPostComposerOptions.createOptions(targetId: nil, targetType: .user, community: nil)
                        let view = AmityPostComposerPage(options: createOptions)
                        let controller = AmitySwiftUIHostingController(rootView: view)
                        host.controller?.navigationController?.pushViewController(controller, animated: true)
                    }
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 1)
                }
                .padding([.leading, .trailing], 16)
            }, communityOnTapAction: { communityModel in
                let createOptions = AmityPostComposerOptions.createOptions(targetId: communityModel.communityId, targetType: .community, community: communityModel)
                let view = AmityPostComposerPage(options: createOptions)
                let controller = AmitySwiftUIHostingController(rootView: view)
                host.controller?.navigationController?.pushViewController(controller, animated: true)
            })
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
}
