//
//  PostContentMediaView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/13/24.
//

import Foundation
import SwiftUI
import AmitySDK

struct PostContentMediaView: View {
    @State private var offset = CGSize.zero
    @Namespace private var animationNamespace
    @StateObject private var viewModel: PostContentMediaViewModel = PostContentMediaViewModel()
    @ObservedObject var viewConfig: AmityViewConfigController
    let post: AmityPostModel
    
    init(post: AmityPostModel, viewConfig: AmityViewConfigController) {
        self.post = post
        self.viewConfig = viewConfig
    }
    
    var body: some View {
        
        if !post.medias.isEmpty {
            getGridView(data: post.medias) { index, media in
                
                ZStack {
                    // Handle different media states
                    Group {
                        if let url = media.getImageURL() {
                            Color.clear
                                .overlay(Color(viewConfig.theme.baseColorShade4))
                                .overlay(
                                    URLImage(url, content: { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    })
                                    .environment(\.urlImageOptions, URLImageOptions.amityOptions)
                                )
                                .contentShape(Rectangle())
                                .applyIf(media.getAltText() != nil) {
                                    $0.accessibility(children: .ignore, labelKey: "Photo \(index + 1) of \(post.medias.count): \(media.getAltText()!)")
                                }
                                            
                        } else {
                            Color(viewConfig.theme.baseColorShade4)
                        }
                    }
                    
                    // Display play button if the media is video
                    if media.type == .video {
                        Image(AmityIcon.videoControlIcon.getImageResource())
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                    }
                    
                    // +X ovelay view if the post has more than 4 medias
                    if index == 3 && post.medias.count > 4 {
                        ZStack {
                            Rectangle()
                                .fill(Color.black.opacity(0.25))
                            
                            Text("+\(post.medias.count - 3)")
                                .applyTextStyle(.headline(.white))
                        }
                        .allowsHitTesting(false)
                        .applyIf(media.getAltText() != nil) {
                            $0.accessibility(children: .combine, labelKey: "Activate to view \(post.medias.count - 3) more photos")
                        }
                    }
                }
                .compositingGroup()
                .clipped()
                .contentShape(Rectangle())
                .onTapGesture {
                    withoutAnimation {
                        viewModel.selectedMediaIndex = index
                        viewModel.showMediaViewer.toggle()
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showMediaViewer) {
                MediaViewer(
                    medias: post.medias, 
                    startIndex: viewModel.selectedMediaIndex, 
                    viewConfig: viewConfig,
                    closeAction: { viewModel.showMediaViewer.toggle() },
                    showEditAction: post.isOwner
                )
            }
        } else {
            EmptyView()
        }
    }
    
    
    @ViewBuilder
    private func getGridView<Content: View, Data: RandomAccessCollection>(data: Data, @ViewBuilder content: @escaping (Data.Index, Data.Element) -> Content) -> some View where Data.Element: Identifiable {
        GeometryReader { geometry in
            VStack(spacing: 4) {
                if data.count == 0 {
                    EmptyView()
                } else if 1...2 ~= data.count {
                    HStack(spacing: 4) {
                        ForEach(0..<data.count, id: \.self) { index in
                            content(index as! Data.Index, data[index as! Data.Index])
                        }
                    }
                } else if 1...data.count ~= data.count {
                    HStack(spacing: 4) {
                        content(0 as! Data.Index, data.first!)
                    }
                    .frame(height: (geometry.size.height / 2) + 30)
                    
                    HStack(spacing: 4) {
                        ForEach(1..<data.count, id: \.self) { index in
                            if index < 4 {
                                content(index as! Data.Index, data[index as! Data.Index])
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    .frame(height: (geometry.size.height / 2) - 30)

                }
            }
        }
    }
}


class PostContentMediaViewModel: ObservableObject {
    @Published var showMediaViewer: Bool = false
    @Published var selectedMediaIndex: Int = 0
}
