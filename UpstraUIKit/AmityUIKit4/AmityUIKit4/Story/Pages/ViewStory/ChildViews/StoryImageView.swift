//
//  StoryImageView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/3/24.
//

import SwiftUI

struct StoryImageView: View {
    private let imageURL: URL
    private let displayMode: ContentMode
    private let size: CGSize
    private let onLoading: () -> Void
    private let onLoaded: () -> Void
    
    init(imageURL: URL, displayMode: ContentMode, size: CGSize, onLoading: @escaping () -> Void, onLoaded: @escaping () -> Void) {
        self.imageURL = imageURL
        self.displayMode = displayMode
        self.size = size
        self.onLoading = onLoading
        self.onLoaded = onLoaded
    }
    
    var body: some View {
        URLImage(imageURL) { progress in
            Color.clear
                .onAppear {
                    onLoading()
                }
            
        } content: { image, imageInfo in
            image
                .resizable()
                .aspectRatio(contentMode: displayMode)
                .frame(width: size.width, height: size.height)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: UIImage(cgImage: imageInfo.cgImage).averageGradientColor ?? [.black]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .onAppear {
                    onLoaded()
                }
                .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.storyImageView)
        }
        .environment(\.urlImageOptions, URLImageOptions.amityOptions)
    }
}
