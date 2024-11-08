//
//  AmityPostAdView.swift
//  AmityUIKit4
//
//  Created by Nishan on 28/6/2567 BE.
//

import SwiftUI
import AmitySDK

struct AmityFeedAdContentComponent: View {
    
    @StateObject private var viewConfig: AmityViewConfigController = AmityViewConfigController(pageId: nil, componentId: .postContentComponent)
    
    @State private var showAdInfo = false
    
    let ad: AmityAd
    
    var body: some View {
        VStack(spacing: 0) {
            header
            content
            footer
        }
        .contentShape(Rectangle())
        .background(Color(viewConfig.theme.backgroundColor))
        .onAppear {
            AdEngine.shared.markAsSeen(ad: ad, placement: .feed)
        }
        .sheet(isPresented: $showAdInfo, content: {
            AmityAdInfoView(advertiserName: ad.advertiser?.companyName ?? "-")
        })
        .updateTheme(with: viewConfig)
    }
    
    @ViewBuilder
    var header: some View {
        HStack(alignment: .top, spacing: 0) {
            
            HStack(spacing: 0) {
                AsyncImage(placeholder: AmityIcon.adAvatarPlaceholder.imageResource, url: URL(string: ad.advertiser?.avatar?.fileURL ?? ""))
                    .frame(width: 32.0, height: 32.0)
                    .clipShape(Circle())
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(ad.advertiser?.name ?? "")
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        .lineLimit(1)
                        .padding(.bottom, 2)
                    
                    AdSponsorLabel()
                }
            }
            
            Spacer()
            
            Button {
                showAdInfo.toggle()
            } label: {
                Image(AmityIcon.infoIcon.imageResource)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade3))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    var footer: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(ad.description)
                    .applyTextStyle(.captionSmall(Color(viewConfig.theme.baseColorShade1)))
                    .lineLimit(1)
                
                Text(ad.headline)
                    .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColor)))
                    .lineLimit(2)
                    .padding(.top, 4)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            if !ad.callToAction.isEmpty && !ad.callToActionUrl.isEmpty {
                Button(action: {
                    handleTapOnAd()
                }, label: {
                    Text(ad.callToAction)
                        .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColor)))
                        .lineLimit(1)
                        .contentShape(Rectangle())
                })
                .buttonStyle(.plain)
                .foregroundColor(Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(viewConfig.theme.highlightColor))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Color(viewConfig.theme.backgroundShade1Color))
        .onTapGesture {
            if !ad.callToActionUrl.isEmpty {
                handleTapOnAd()
            }
        }
    }
    
    @ViewBuilder
    var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(ad.body)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                    .lineLimit(6)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 1)
            }
            .padding(.horizontal, 16)
            
            KFImage.url(URL(string: ad.image1_1?.largeFileURL ?? ""))
                .placeholder({
                    Image(AmityIcon.adAvatarPlaceholder.imageResource)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.vertical, 8)
                })
                .loadDiskFileSynchronously()
                .cacheMemoryOnly()
                .fade(duration: 0.25)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
        }
        .padding(.top, 8)
    }
    
    func handleTapOnAd() {
        guard let actionURL = URL(string: ad.callToActionUrl) else { return }
        
        AdEngine.shared.markAsClicked(ad: ad, placement: .feed)
        
        UIApplication.shared.open(actionURL)
    }
}
