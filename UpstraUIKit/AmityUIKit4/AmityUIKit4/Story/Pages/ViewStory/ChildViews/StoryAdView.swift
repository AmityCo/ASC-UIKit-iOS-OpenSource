//
//  StoryAdView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 7/1/24.
//

import AmitySDK
import SwiftUI

struct StoryAdView<Content: View>: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @EnvironmentObject var storyPageViewModel: AmityViewStoryPageViewModel
    @EnvironmentObject var storyCoreViewModel: StoryCoreViewModel
    @State private var showAdInfo: Bool = false
    let ad: AmityAd
    let gestureView: () -> Content
    
    init(ad: AmityAd, gestureView: @escaping () -> Content) {
        self.ad = ad
        self.gestureView = gestureView
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                GeometryReader { geometry in
                    KFImage.url(URL(string: ad.image9_16?.largeFileURL ?? ""))
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
                        .startLoadingBeforeViewAppear()
                        .fade(duration: 0.25)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .background(Color.black)
                        .cornerRadius(8)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                
                gestureView()
                    .padding(.bottom, 30)
                
                /// Call to action view
                if !ad.callToAction.isEmpty && !ad.callToActionUrl.isEmpty {
                    VStack(alignment: .center, spacing: 12) {
                        Image(AmityIcon.upArrowIcon.getImageResource())
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 30, height: 10)
                            .foregroundColor(Color(viewConfig.defaultLightTheme.backgroundColor.withAlphaComponent(0.8)))
                        
                        HStack(spacing: 0) {
                            Text(ad.callToAction)
                                .applyTextStyle(.bodyBold(Color(viewConfig.defaultLightTheme.baseColor)))
                                .lineLimit(1)
                                .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        }
                        .frame(height: 40)
                        .background(Color(viewConfig.defaultLightTheme.backgroundColor.withAlphaComponent(0.8)))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding([.bottom, .leading, .trailing], 30)
                    }
                    .onTapGesture {
                        guard let url = URL(string: ad.callToActionUrl) else { return }
                        ad.analytics.markLinkAsClicked(placement: .story)
                
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                /// Info button view
                HStack {
                    Spacer()
                    
                    Button {
                        showAdInfo.toggle()
                    } label: {
                        Image(AmityIcon.infoIcon.imageResource)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(Color(viewConfig.defaultLightTheme.baseColorShade3))
                    }
                    .frame(width: 20, height: 20)
                }
                .padding([.bottom, .trailing], 5)

                /// Avatar and name view
                VStack(alignment: .center) {
                    HStack {
                        AsyncImage(placeholder: AmityIcon.adAvatarPlaceholder.getImageResource(), url: URL(string: ad.advertiser?.avatar?.largeFileURL ?? ""))
                            .frame(width: 45, height: 45)
                            .clipShape(Circle())
                            .padding(.leading, 16)
                        
                        VStack(alignment: .leading) {
                            HStack(alignment: .center) {
                                Text(ad.advertiser?.name ?? "")
                                    .applyTextStyle(.bodyBold(.white))
                                    .frame(height: 20)
                                
                                Spacer(minLength: 80)
                            }
                            
                            AdSponsorLabel()
                            
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .offset(y: 30) // height + padding top, bottom of progressBarView
            }
            
            Rectangle()
                .fill(Color.black)
                .frame(height: 81)

        }
        .sheet(isPresented: $showAdInfo, content: {
            AmityAdInfoView(advertiserName: ad.advertiser?.companyName ?? "-")
        })
//        .onChange(of: showAdInfo) { isShown in
//            storyPageViewModel.shouldRunTimer = !isShown
//            storyCoreViewModel.playVideo = !isShown
//        }
        .onAppear {
            ad.analytics.markAsSeen(placement: .story)
        }
    }
}
