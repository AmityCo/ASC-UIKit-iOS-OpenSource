//
//  AmityEventInfoComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 7/11/25.
//

import AmitySDK
import SwiftUI

struct AmityEventInfoComponent: View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @ObservedObject var viewModel: AmityEventDetailPageViewModel
        
    init(viewModel: AmityEventDetailPageViewModel) {
        self.viewModel = viewModel
    }
    
    @StateObject private var viewConfig: AmityViewConfigController = .init(pageId: .socialHomePage)
    
    /// Resolves the thumbnail URL using priority: Event cover image -> creator-uploaded → live thumbnail → placeholder
    private var resolvedThumbnailURL: String {
        let room = viewModel.event?.room
        
        // 1. Event cover image (if available) - this takes precedence over room thumbnails
        if let eventCoverImageUrl = viewModel.event?.coverImage?.mediumFileURL {
            return eventCoverImageUrl
        }
        
        // 2. Creator-uploaded thumbnail (thumbnailFileId)
        if let creatorThumbnail = room?.getThumbnail()?.mediumFileURL, !creatorThumbnail.isEmpty {
            return creatorThumbnail
        }
        
        // 3. Live thumbnail (Mux auto-generated)
        if let liveThumbnail = room?.liveThumbnailUrl, !liveThumbnail.isEmpty {
            return liveThumbnail
        }
        
        // 4. No thumbnail available → placeholder
        return ""
    }

    private var contentHeight: CGFloat {
        let height16x9: CGFloat = 208
        let height4x5: CGFloat = 480
        
        let room = viewModel.event?.room
        let streamStatus = room?.status ?? .idle
        
        // Idle state always uses 16:9 aspect ratio with placeholder thumbnail
        if streamStatus == .idle {
            return height16x9
        }
        
        // Event cover image (if available)
        if let eventCoverImageUrl = viewModel.event?.coverImage?.mediumFileURL {
            return height16x9
        }
        
        // Creator-uploaded thumbnail uses platform default (16:9 for iOS)
        if let creatorThumbnail = room?.getThumbnail()?.mediumFileURL, !creatorThumbnail.isEmpty {
            return height16x9
        }

        // Live/recorded thumbnails use resolution data to determine aspect ratio
        let resolution: AmityRoomResolution? = {
            switch streamStatus {
            case .live:
                return room?.liveResolution
            case .recorded:
                return room?.recordedResolution
            default:
                return room?.liveResolution ?? room?.recordedResolution
            }
        }()

        if let width = resolution?.width, let height = resolution?.height, width > 0, height > 0 {
            // Portrait or square → 4:5, Landscape → 16:9
            return height >= width ? height4x5 : height16x9
        }

        // iOS default: 16:9
        return height16x9
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            Text(AmityLocalizedStringSet.Social.eventInfoAboutTheEvent.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
            
            ExpandableText(viewModel.event?.description ?? "")
                .lineLimit(10)
                .moreButtonText(AmityLocalizedStringSet.Social.eventInfoSeeMore.localizedString)
                .font(AmityTextStyle.body(.clear).getFont())
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .attributedColor(viewConfig.theme.primaryColor)
                .moreButtonColor(Color(viewConfig.theme.primaryColor))
                .expandAnimation(.easeOut(duration: 0.25))
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
            
            let virtualEventLinkTitle = viewModel.event?.isLiveStreamEvent ?? false ? AmityLocalizedStringSet.Social.eventInfoLiveStream.localizedString : AmityLocalizedStringSet.Social.eventInfoEventLink.localizedString
            
            Text(viewModel.event?.type == .inPerson ? AmityLocalizedStringSet.Social.eventInfoEventAddress.localizedString : virtualEventLinkTitle)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .padding(.top, 24)
            
            if viewModel.event?.type == .inPerson {
                ExpandableText(viewModel.event?.location ?? "")
                    .lineLimit(100)
                    .moreButtonText(AmityLocalizedStringSet.Social.eventInfoSeeMore.localizedString)
                    .font(AmityTextStyle.body(.clear).getFont())
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .attributedColor(viewConfig.theme.primaryColor)
                    .moreButtonColor(Color(viewConfig.theme.primaryColor))
                    .expandAnimation(.easeOut(duration: 0.25))
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
                
                Button {
                    UIPasteboard.general.string = viewModel.event?.location

                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.eventInfoAddressCopied.localizedString)
                } label: {
                    HStack {
                        Image(AmityIcon.copyTextIcon.imageResource)

                        Text(AmityLocalizedStringSet.Social.eventInfoCopy.localizedString)
                    }
                }
                .buttonStyle(AmityLineButtonStyle(viewConfig: viewConfig))
                .padding(.top, 16)
                .padding(.bottom, 32)
            } else {
                if viewModel.event?.isLiveStreamEvent ?? false {
                    let stream = viewModel.event?.room
                    let streamStatus = stream?.status ?? .idle
                    
                    // If livestream has not started yet
                    if streamStatus == .idle {
                        Text(AmityLocalizedStringSet.Social.eventDetailHeaderLivestreamSetupInfo.localizedString)
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                            .padding(.top, 4)
                    }
                    
                    ZStack(alignment: .center) {
                        AsyncImage(placeholder: AmityIcon.livestreamPlaceholderGray.imageResource, url: URL(string: resolvedThumbnailURL), contentMode: .fill)
                            .frame(height: contentHeight)
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Spacer()
                                
                                Text(getStreamStatus(status: streamStatus).uppercased())
                                    .applyTextStyle(.captionBold(.white))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(stream?.status == .live ? Color(UIColor(hex: "FF305A")) : Color.black.opacity(0.5))
                                    .blurBackground(style: .regular)
                                    .cornerRadius(4, corners: .allCorners)
                                    .padding(12)
                            }
                            
                            Spacer()
                        }
                        
                        Image(AmityIcon.videoControlIcon.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .visibleWhen(streamStatus == .live || streamStatus == .recorded)
                    }
                    .onTapGesture {
                        guard let event = viewModel.event, let room = event.room else { return }
                        
                        guard room.status != .idle && room.status != .ended else { return }
                        
                        guard let post = stream?.post else {
                            Log.add(event: .error, "No post found for livestream room.")
                            return
                        }
                        
                        // attahch room to post model as the post from event does not have child room post
                        let postModel = AmityPostModel(post: post)
                        postModel.room = room
                        postModel.event = event
                        
                        let page = AmityLivestreamPlayerPage(postModel: postModel)
                        let vc = AmitySwiftUIHostingController(rootView: page)
                        vc.modalPresentationStyle = .overFullScreen
                        host.controller?.present(vc, animated: true)
                    }
                    .padding(.top, 16)
                    
                } else {
                    ExpandableText(viewModel.event?.externalUrl ?? "")
                        .lineLimit(100)
                        .moreButtonText(AmityLocalizedStringSet.Social.eventInfoSeeMore.localizedString)
                        .font(AmityTextStyle.body(.clear).getFont())
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .attributedColor(viewConfig.theme.primaryColor)
                        .moreButtonColor(Color(viewConfig.theme.primaryColor))
                        .expandAnimation(.easeOut(duration: 0.25))
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                    
                    Button {
                        UIPasteboard.general.string = viewModel.event?.externalUrl

                        Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.eventInfoLinkCopied.localizedString)
                    } label: {
                        HStack {
                            Image(AmityIcon.copyTextIcon.imageResource)

                            Text(AmityLocalizedStringSet.Social.eventInfoCopy.localizedString)
                        }
                    }
                    .buttonStyle(AmityLineButtonStyle(viewConfig: viewConfig))
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 32)
    }
    
    func getStreamStatus(status: AmityRoomStatus) -> String {
        switch status {
        case .ended, .terminated:
            return AmityLocalizedStringSet.Social.eventInfoStreamStatusEnded.localizedString
        case .live, .waitingReconnect:
            return AmityLocalizedStringSet.Social.eventInfoStreamStatusLive.localizedString
        case .recorded:
            return AmityLocalizedStringSet.Social.eventInfoStreamStatusRecorded.localizedString
        case .idle:
            return AmityLocalizedStringSet.Social.eventInfoStreamStatusUpcomingLive.localizedString
        @unknown default:
            return ""
        }
    }
}
