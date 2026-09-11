//
//  StoryImageView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/3/24.
//

import SwiftUI

struct StoryImageView: View {
    private let imageURL: URL
    /// `nil` falls back to the image's own orientation — see `resolvedDisplayMode(for:)`.
    private let displayMode: ContentMode?
    private let size: CGSize
    private let onLoading: () -> Void
    private let onLoaded: () -> Void
    
    init(imageURL: URL, displayMode: ContentMode?, size: CGSize, onLoading: @escaping () -> Void, onLoaded: @escaping () -> Void) {
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
            let loadedImage = UIImage(cgImage: imageInfo.cgImage)

            image
                .resizable()
                .aspectRatio(contentMode: resolvedDisplayMode(for: loadedImage))
                .frame(width: size.width, height: size.height)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: loadedImage.averageGradientColor ?? [.black]),
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

    /// A story that specified its own mode is honoured. Otherwise the orientation decides, matching
    /// what `AmityDraftStoryPage` picks at creation: portrait fills, landscape fits so a wide image
    /// is letterboxed rather than cropped.
    private func resolvedDisplayMode(for image: UIImage) -> ContentMode {
        if let displayMode { return displayMode }
        return image.orientation == .portrait ? .fill : .fit
    }
}
