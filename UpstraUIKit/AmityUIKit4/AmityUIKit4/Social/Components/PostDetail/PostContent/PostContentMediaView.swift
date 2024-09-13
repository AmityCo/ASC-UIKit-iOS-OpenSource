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
    let post: AmityPostModel
    
    init(post: AmityPostModel) {
        self.post = post
    }
    
    var body: some View {
        getGridView(data: post.medias) { index, media in
            if let url = media.getImageURL() {
                ZStack {
                    Color.clear
                        .overlay(
                            URLImage(url, content: { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            })
                            .environment(\.urlImageOptions, URLImageOptions.amityOptions)
                        )
                        .compositingGroup()
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withoutAnimation {
                                viewModel.selectedMediaIndex = index
                                viewModel.showMediaViewer.toggle()
                            }
                        }
                    
                    if media.type == .video {
                        Image(AmityIcon.videoControlIcon.getImageResource())
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showMediaViewer) {
            MediaViewer(medias: post.medias, startIndex: viewModel.selectedMediaIndex, closeAction: { viewModel.showMediaViewer.toggle() })
        }
    }
    
    
    @ViewBuilder
    private func getGridView<Content: View, Data: RandomAccessCollection>(data: Data, @ViewBuilder content: @escaping (Data.Index, Data.Element) -> Content) -> some View where Data.Element: Identifiable {
        GeometryReader { geometry in
            VStack(spacing: 4) {
                if 1...2 ~= data.count {
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
                                ZStack {
                                    content(index as! Data.Index, data[index as! Data.Index])
                                    
                                    if index == 3 && data.count > 4 {
                                        Rectangle()
                                            .fill(Color.black.opacity(0.25))
                                            .overlay (
                                                Text("+\(data.count - 3)")
                                                    .font(.system(size: 20, weight: .semibold))
                                                    .foregroundColor(.white)
                                            )
                                            .allowsHitTesting(false)
                                    }
                                }
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
