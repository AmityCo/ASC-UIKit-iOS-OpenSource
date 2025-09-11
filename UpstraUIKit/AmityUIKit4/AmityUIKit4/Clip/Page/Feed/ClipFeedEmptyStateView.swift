//
//  ClipFeedEmptyStateView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 23/6/25.
//

import SwiftUI

struct ClipFeedEmptyStateView: View {
    
    let onTapAction: ((ClipFeedAction) -> Void)?
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    var body: some View {
        ZStack {
            Color(viewConfig.theme.secondaryColorShade1)
                .edgesIgnoringSafeArea(.all)
            
            ClipFeedGradientLayer()
            
            VStack(spacing: 0) {
                Image(AmityIcon.emptyClipFeedIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                
                Text("Your feed is empty")
                    .applyTextStyle(.titleBold(Color.white))
                    .padding(.top, 16)
                
                Text("Find community or create your own. ")
                    .applyTextStyle(.caption(.white))
                    .padding(.top, 8)
                
                Button {
                    onTapAction?(.exploreCommunity)
                } label: {
                    HStack {
                        Image(AmityIcon.clipGlobeIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                        
                        Text("Explore community")
                            .applyTextStyle(.bodyBold(Color.white))
                    }
                }
                .padding(.vertical, 16)
                .foregroundColor(.white)
                .buttonStyle(AmityLineButtonStyle(viewConfig: viewConfig, size: .compact, vPadding: 10, borderColor: .white))
                
                Button {
                    onTapAction?(.createCommunity)
                } label: {
                    Text("Create community")
                        .applyTextStyle(.bodyBold(Color.white))
                        .padding(.bottom, 16)
                }
            }
        }
    }
}

struct ClipFeedLoadingStateView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let isError: Bool
    
    var body: some View {
        ZStack {
            Color(viewConfig.theme.secondaryColorShade1)
                .edgesIgnoringSafeArea(.all)
            
            ClipFeedGradientLayer()
            
            VStack(alignment: .leading, spacing: 0) {
                
                Spacer()
                
                HStack(spacing: 8) {
                    SkeletonRectangle(height: 32, width: 32, cornerRadius: 32, color: viewConfig.theme.secondaryColor.blend(.shade2))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonRectangle(height: 8, width: 180, color: viewConfig.theme.secondaryColor.blend(.shade2))
                        SkeletonRectangle(height: 8, width: 64, color: viewConfig.theme.secondaryColor.blend(.shade2))
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonRectangle(height: 8, width: 284, color: viewConfig.theme.secondaryColor.blend(.shade2))
                    SkeletonRectangle(height: 8, width: 180, color: viewConfig.theme.secondaryColor.blend(.shade2))
                }
                .padding(.top, 24)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .opacity(!isError ? 1 : 0)
            
            VStack(spacing: 0) {
                Image(AmityIcon.clipLoadingErrorIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                
                Text("Unable to load clip")
                    .applyTextStyle(.bodyBold(Color.white))
                    .padding(.vertical, 16)
            }
            .opacity(isError ? 1 : 0)
        }
    }
}

struct ClipFeedGradientLayer: View {
    
    let gradientColor: Color = .black
    
    var body: some View {
        VStack {
            Rectangle()
                .foregroundColor(.clear)
                .background(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: gradientColor.opacity(0.35), location: 0.00),
                            Gradient.Stop(color: gradientColor.opacity(0), location: 1.00),
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .edgesIgnoringSafeArea(.top)
                )
            
            Spacer()
            
            Rectangle()
                .foregroundColor(.clear)
                .background(
                    LinearGradient(stops: [
                        Gradient.Stop(color: gradientColor.opacity(0.8), location: 0.00),
                        Gradient.Stop(color: gradientColor.opacity(0), location: 1.00),
                    ], startPoint: .bottom, endPoint: .center)
                    .edgesIgnoringSafeArea(.bottom)
                    
                )
        }
        
    }
}

struct ClipFeedDeletedStateView: View {
    
    let onTapAction: ((ClipFeedAction) -> Void)?
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    var body: some View {
        ZStack {
            // #636878
            Color(viewConfig.theme.secondaryColorShade1)
                .edgesIgnoringSafeArea(.all)
            
            ClipFeedGradientLayer()
            
            VStack(spacing: 0) {
                Image(AmityIcon.clipDeletedIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                
                Text("This clip is no longer available.")
                    .applyTextStyle(.body(Color.white))
                    .padding(.top, 16)
                
                Button {
                    onTapAction?(.watchNextClip)
                } label: {
                    Text("Watch next clip")
                        .applyTextStyle(.bodyBold(Color.white))
                }
                .contentShape(Rectangle())
                .padding(.vertical, 16)
                .foregroundColor(.white)
                .buttonStyle(AmityLineButtonStyle(viewConfig: viewConfig, size: .compact, vPadding: 10, borderColor: .white))
            }
        }
    }
}
