//
//  AmityLivestreamTerminatedPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 12/3/25.
//

import SwiftUI

public enum AmityLivestreamTerminatedPageType {
    case watcher
    case streamer
    
    var icon: ImageResource {
        switch self {
        case .watcher:
            AmityIcon.LiveStream.terminatedPageWatcher.imageResource
        case .streamer:
            AmityIcon.LiveStream.terminatedPageStreamer.imageResource
        }
    }
    
    var title: String {
        switch self {
        case .watcher:
            return AmityLocalizedStringSet.Social.liveStreamTerminatedWatcherTitle.localizedString
        case .streamer:
            return AmityLocalizedStringSet.Social.liveStreamTerminatedStreamerTitle.localizedString
        }
    }
    
    var description: String {
        switch self {
        case .watcher:
            return AmityLocalizedStringSet.Social.liveStreamTerminatedWatcherDesc.localizedString
        case .streamer:
            return AmityLocalizedStringSet.Social.liveStreamTerminatedStreamerDesc.localizedString
        }
    }
    
    // icon, text
    var contents: [(UUID, ImageResource, String)] {
        switch self {
        case .watcher:
            return [
                (UUID(), AmityIcon.LiveStream.terminatedContentPlayback.imageResource, AmityLocalizedStringSet.Social.liveStreamTerminatedPlaybackDesc.localizedString)
            ]
        case .streamer:
            return [
                (UUID(), AmityIcon.LiveStream.terminatedContentViewer.imageResource, AmityLocalizedStringSet.Social.liveStreamTerminatedStreamerContentDesc.localizedString),
                (UUID(), AmityIcon.LiveStream.terminatedContentPlayback.imageResource, AmityLocalizedStringSet.Social.liveStreamTerminatedPlaybackDesc.localizedString)
            ]
        }
    }
}

public struct AmityLivestreamTerminatedPage: AmityPageView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    @StateObject private var viewConfig: AmityViewConfigController

    let type: AmityLivestreamTerminatedPageType
    
    var onDismiss: (() -> Void)?
    
    public var id: PageId {
        return .liveStreamTerminatedPage
    }
    
    public init(type: AmityLivestreamTerminatedPageType = .streamer, onDismiss: (() -> Void)? = nil) {
        self.type = type
        self.onDismiss = onDismiss
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .userProfilePage))
    }
    
    public var body: some View {
        VStack {
            AmityNavigationBar(title: AmityLocalizedStringSet.Social.liveStreamTerminatedPageTitle.localizedString, showBackButton: false, showDivider: true)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    Image(type.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .padding(.top, 24)
                        
                    Text(type.title)
                        .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                    
                    Text(type.description)
                        .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade1)))
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 1)
                        .padding(.vertical, 24)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(AmityLocalizedStringSet.Social.liveStreamTerminatedPageDescSectionTitle.localizedString)
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                            .padding(.bottom, 16)
                        
                        ForEach(type.contents, id: \.0) { item in
                            HStack(alignment: .top, spacing: 12) {
                                Image(item.1)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                
                                Text(item.2)
                                    .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                                    .padding(.bottom, 16)
                                    .padding(.top, 2)
                            }
                        }
                    }
                }
            }
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
                .padding(.vertical, 16)
            
            Button {
                host.controller?.dismiss(animated: true)
                
                onDismiss?()
            } label: {
                Text(AmityLocalizedStringSet.Chat.okButton.localizedString)
                    .applyTextStyle(.bodyBold(.white))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(height: 40)
            .background(Color(viewConfig.theme.primaryColor))
            .cornerRadius(8, corners: .allCorners)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .updateTheme(with: viewConfig)
    }
}

#if DEBUG
#Preview {
    AmityLivestreamTerminatedPage(type: .watcher)
}
#endif

