//
//  AmityEventPostTargetSelectionPage.swift
//  AmityUIKit4
//
//  Copyright © 2026 Amity. All rights reserved.
//

import SwiftUI
import AmitySDK


public struct AmityEventPostTargetSelectionPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId {
        .postTargetSelectionPage
    }

    @StateObject private var viewConfig: AmityViewConfigController
    private let event: AmityEvent

    /// A private-community event can only be posted to its own community.
    private var isPrivateEvent: Bool {
        event.originType == .community && event.isOriginPublic == false
    }

    public init(event: AmityEvent) {
        self.event = event
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .postTargetSelectionPage))
    }

    public var body: some View {
        VStack(spacing: 0) {
            let configuredTitle = viewConfig.getConfig(elementId: .title, key: "text", of: String.self)
            let navTitle = (configuredTitle?.isEmpty ?? true) ? AmityLocalizedStringSet.Social.postTo.localizedString : (configuredTitle ?? "")
            let closeIcon = viewConfig.getConfig(elementId: .closeButtonElement, key: "image", of: String.self) ?? ""
            AmityPostTargetSelectionPage.HeaderView(title: navTitle, closeIcon: closeIcon) {
                if let navigationController = host.controller?.navigationController {
                    navigationController.dismiss(animated: true)
                } else {
                    host.controller?.dismiss(animated: true)
                }
            }

            if isPrivateEvent {
                privateTargetView
            } else {
                TargetSelectionView(headerView: {
                    AmityPostTargetSelectionPage.MyTimelineView {
                        openComposer(targetId: nil, targetType: .user)
                    }
                }, communityOnTapAction: { communityModel in
                    openComposer(targetId: communityModel.communityId, targetType: .community)
                }, contentType: .post)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }

    /// Private-community event: banner + only the origin community (locked); no My Timeline.
    @ViewBuilder
    private var privateTargetView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(AmityLocalizedStringSet.Social.eventPostPrivateTargetBanner.localizedString)
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .background(Color(viewConfig.theme.baseColorShade4))

            Text(AmityLocalizedStringSet.Social.myCommunities.localizedString)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade3)))
                .padding([.leading, .top], 16)
                .padding(.bottom, 8)

            if let community = event.targetCommunity {
                originCommunityRow(AmityCommunityModel(object: community))
            }

            Spacer()
        }
    }

    private func originCommunityRow(_ community: AmityCommunityModel) -> some View {
        HStack(spacing: 0) {
            AsyncImage(
                placeholderView: {
                    defaultCommunityPlaceholderView(viewConfig: viewConfig, size: 40)
                },
                url: URL(string: community.avatarURL))
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 12))

            Image(AmityIcon.getImageResource(named: "lockBlackIcon"))
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .padding(.trailing, 8)

            Text(community.displayName)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            openComposer(targetId: community.communityId, targetType: .community)
        }
    }

    private func openComposer(targetId: String?, targetType: AmityPostTargetType) {
        let options = AmityPostComposerOptions.createEventPostOptions(event: event, targetId: targetId, targetType: targetType)
        let view = AmityPostComposerPage(options: options)
        let controller = AmitySwiftUIHostingController(rootView: view)
        host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
}
