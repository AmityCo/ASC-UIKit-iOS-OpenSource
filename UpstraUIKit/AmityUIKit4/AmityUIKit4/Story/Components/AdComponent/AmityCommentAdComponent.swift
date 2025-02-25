//
//  AmityCommentAdComponent.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 2/7/2567 BE.
//

import SwiftUI
import AmitySDK

struct AmityCommentAdComponent: View {
    @Environment(\.openURL) var openURL
    
    @StateObject private var viewConfig: AmityViewConfigController = AmityViewConfigController(pageId: nil, componentId: .postContentComponent)
    
    let ad: AmityAd
    
    let selctedAdInfoAction: ((AmityAd) -> Void)?
    
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                
                AsyncImage(placeholder: AmityIcon.adAvatarPlaceholder.imageResource, url: URL(string: ad.advertiser?.avatar?.fileURL ?? ""))
                    .frame(width: 32, height: 32)
                    .clipShape(.circle)
                    .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 8))
                
                VStack {
                    ZStack(alignment: .topTrailing) {
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(ad.advertiser?.name ?? "")
                                    .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColor)))
                                    .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.nameTextView)
                                Spacer()
                            }
                            
                            AdSponsorLabel()
                            
                            Text(ad.body)
                                .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                                .lineLimit(6)
                                .multilineTextAlignment(.leading)
                            
                            Button {
                                if let url = URL(string: ad.callToActionUrl) {
                                    openURL(url)
                                } else {
                                    Log.ads.debug("Error converting url from callToActionURL")
                                }
                            } label: {
                                HStack(spacing: 0) {
                                    KFImage.url(URL(string: ad.image1_1?.largeFileURL ?? ""))
                                        .placeholder({
                                            Image(AmityIcon.adAvatarPlaceholder.imageResource)
                                                .aspectRatio(contentMode: .fill)
                                                .background(Color.red.opacity(0.1))
                                                .cornerRadius(8)
                                                .padding(.vertical, 8)
                                        })
                                        .loadDiskFileSynchronously()
                                        .cacheMemoryOnly()
                                        .fade(duration: 0.25)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, alignment: .center)
                                        .background(Color.red.opacity(0.1))
                                    
                                    
                                    VStack {
                                        VStack(alignment: .leading) {
                                            Text(ad.description)
                                                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                                                .lineLimit(1)
                                            
                                            Text(ad.headline)
                                                .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColor)))
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(2)
                                            
                                            Spacer()
                                            
                                            Text(ad.callToAction)
                                                .applyTextStyle(.bodyBold(.white))
                                                .lineLimit(1)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .background(Color(viewConfig.theme.highlightColor))
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                                .opacity(ad.callToAction.isEmpty ? 0 : 1)
                                        }
                                        .padding(.all, 12)

                                    }
                                    .background(Color(viewConfig.theme.backgroundColor))
                                    
                                    Spacer()
                                }
                                .background(Color(viewConfig.theme.backgroundColor))
                                .frame(height: 118)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.top, 4)
                            }
                        }
                        .padding(.all, 12)
                        
                        Button {
                            selctedAdInfoAction?(ad)
                        } label: {
                            Image(AmityIcon.infoIcon.imageResource)
                                .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                        }
                        .buttonStyle(.plain)
                        .padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 4))
                    }
                    .background(Color(viewConfig.theme.baseColorShade4))
                    .clipShape(RoundedCorner(radius: 12, corners: [.topRight, .bottomLeft, .bottomRight]))
                    .padding(.trailing, 16)
                }
            }
        }
        .contentShape(Rectangle())
        .background(Color(viewConfig.theme.backgroundColor))
        .padding([.top, .bottom], 3)
        .onAppear {
            AdEngine.shared.markAsSeen(ad: ad, placement: .comment)
        }
        .updateTheme(with: viewConfig)
    }
    
}

struct AdSponsorLabel: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    var body: some View {
        HStack(spacing: 0) {
            Image(AmityIcon.starIcon.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundColor(Color(viewConfig.theme.backgroundColor))
                .padding(.leading, 4)
            
            Text(AmityLocalizedStringSet.Social.sponsored.localizedString)
                .applyTextStyle(.captionSmall(.white))
                .padding(.leading, 2)
                .padding(.trailing, 6)
        }
        .frame(height: 18)
        .background(Color(viewConfig.theme.baseColorShade1.withAlphaComponent(0.5)))
        .clipShape(Capsule())
    }
}
