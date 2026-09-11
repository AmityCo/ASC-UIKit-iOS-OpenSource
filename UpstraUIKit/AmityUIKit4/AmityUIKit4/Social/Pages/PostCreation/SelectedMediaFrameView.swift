//
//  SelectedMediaFrameView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/10/26.
//

import SwiftUI
import AVKit
import AmitySDK

/// One frame of the composer's media preview: the media, its per-frame controls, and its upload state.
struct SelectedMediaFrameView: View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @EnvironmentObject private var mediaViewModel: AmityMediaAttachmentViewModel
    @EnvironmentObject private var postComposerViewModel: AmityPostComposerViewModel

    /// `@ObservedObject`, not `@StateObject` — a carousel recycles its frames, and `@StateObject` would
    /// re-initialise on every recycle.
    @ObservedObject var media: AmityMedia

    let index: Int
    let total: Int
    let removeAction: () -> Void
    let onTap: () -> Void

    @StateObject private var networkMonitor = NetworkMonitor()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            mediaContent
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)

            removeButton

            bottomControls
                .visibleWhen(media.isUploaded())
        }
        .clipped()
        .contentShape(Rectangle())
        .onAppear {
            mediaViewModel.startUploadIfNeeded(for: media)
        }
    }

    // MARK: - Media

    @ViewBuilder
    private var mediaContent: some View {
        ZStack {
            Color.clear.overlay(thumbnail)

            if media.type == .video {
                Image(AmityIcon.videoControlIcon.getImageResource())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
            }

            if case .uploading(let progress) = media.state {
                Color.black.opacity(0.5)
                uploadRing(progress)
            }

            if case .error = media.state {
                failureIndicator
            }

            if !networkMonitor.isConnected {
                failureIndicator
            }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if media.type == .image {
            if let localImage = media.localUIImage {
                Image(uiImage: localImage).resizable().scaledToFill()
            } else if let url = media.getImageURL() {
                remoteThumbnail(url)
            } else if let path = media.localUrl?.path, let image = UIImage(contentsOfFile: path) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Color.gray.opacity(0.2)
            }
        } else {
            if let thumbnail = media.generatedThumbnailImage {
                Image(uiImage: thumbnail).resizable().scaledToFill()
            } else if let url = media.getImageURL() {
                remoteThumbnail(url)
            } else {
                Color.gray.opacity(0.2)
            }
        }
    }

    private func remoteThumbnail(_ url: URL) -> some View {
        Color.clear
            .overlay(
                KFImage.url(url)
                    .placeholder { ProgressView().progressViewStyle(CircularProgressViewStyle()) }
                    .resizable()
                    .fromMemoryCacheOrRefresh()
                    .startLoadingBeforeViewAppear()
                    .aspectRatio(contentMode: .fill)
            )
            .clipped()
    }

    // MARK: - Upload states

    private func uploadRing(_ progress: CGFloat) -> some View {
        Circle()
            .stroke(lineWidth: 3.0)
            .fill(Color.white)
            .overlay(
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(
                        Color(AmityUIKitConfigController.shared.getTheme().primaryColor),
                        lineWidth: 3.0
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.01), value: progress)
            )
            .frame(width: 22, height: 22)
    }

    /// The legacy glyph. The specified `exclamation-circle` exists only in the new icon set, and social
    /// should not become its first consumer for one glyph.
    private var failureIndicator: some View {
        ZStack {
            Color.black.opacity(0.5)
            Image(AmityIcon.mediaUploadErrorIcon.getImageResource())
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
        }
    }

    // MARK: - Controls

    private var removeButton: some View {
        Button(action: removeAction) {
            Image(AmityIcon.backgroundedCloseIcon.getImageResource())
                .resizable()
                .scaledToFill()
                .frame(width: 20, height: 20)
        }
        .padding(.top, 8)
        .padding(.trailing, 8)
        .accessibilityLabel("Remove \(media.type == .video ? "video" : "image") \(index + 1) of \(total)")
    }

    private var bottomControls: some View {
        VStack {
            Spacer()
            HStack {
                if showsAltText {
                    altTextButton
                }
                Spacer()
                productTagBadge
            }
        }
        .padding(8)
    }

    /// Images only, and only for media added in this session — media already published on the post gets
    /// no control at all when editing.
    private var showsAltText: Bool {
        media.isLocal() && media.type == .image
    }

    private var altTextButton: some View {
        Button {
            guard let imageData = media.image else { return }
            let configMode: AltTextConfigMode
            if let altText = media.altText, !altText.isEmpty {
                configMode = .edit(altText, .image(imageData))
            } else {
                configMode = .create(.image(imageData))
            }
            let component = AmityAltTextConfigComponent(mode: configMode) { altText in
                media.altText = altText
            }
            host.controller?.present(AmitySwiftUIHostingController(rootView: component), animated: true)
        } label: {
            HStack(spacing: 4) {
                Text(AmityLocalizedStringSet.Social.altTextButtonTitle.localizedString)
                    .applyTextStyle(.captionBold(.white))

                if let altText = media.altText ?? media.getAltText(hasDefault: false), !altText.isEmpty {
                    Image(AmityIcon.checkMarkIcon.getImageResource())
                        .resizable()
                        .scaledToFill()
                        .frame(width: 16, height: 12)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.black.opacity(0.5)))
        }
    }

    private var productTagBadge: some View {
        AmityProductTagBadgeView(count: media.produtTags.count,
                                 icon: media.produtTags.isEmpty ? .tagIcon : .productTagFilledIcon)
            .isHidden(!postComposerViewModel.isProductCatalogueEnabled
                      || (media.produtTags.isEmpty
                          && postComposerViewModel.productTags.count == postComposerViewModel.productTagLimit))
            .onTapGesture { presentProductTagSelection() }
    }

    private func presentProductTagSelection() {
        let initialSelection = media.produtTags.map { $0.object }
        let mode: AmityProductTagSelectionMode = media.produtTags.isEmpty ? .create : .edit
        var selectedProductTags: [AmityProductTagModel] = media.produtTags
        var vc: AmitySwiftUIHostingController<AmityProductTagSelectionComponent>?

        let existingProducts = postComposerViewModel.productTags.map { $0.productId }

        let component = AmityProductTagSelectionComponent(
            mode: mode,
            initialSelection: initialSelection,
            existingProducts: existingProducts,
            onClose: { vc?.dismiss(animated: true) },
            onDone: {
                media.produtTags = selectedProductTags

                if let mediaFileId = media.getFileId() {
                    let mediaProductTags = selectedProductTags.map {
                        AmityMediaProductTag(productId: $0.productId, product: $0.object)
                    }
                    postComposerViewModel.attachmentProductTags.set(fileId: mediaFileId, tags: mediaProductTags)
                    postComposerViewModel.updateProductTags(medias: mediaViewModel.medias)
                }

                let message = initialSelection.isEmpty
                    ? AmityLocalizedStringSet.Social.productTagsAdded.localizedString
                    : AmityLocalizedStringSet.Social.productTagsUpdated.localizedString
                Toast.showToast(style: .success, message: message)

                vc?.dismiss(animated: true)
            },
            onTagChanges: { products in
                selectedProductTags = products.map {
                    AmityProductTagModel(object: $0, range: NSRange(), contentType: .media)
                }
            }
        )

        vc = AmitySwiftUIHostingController(rootView: component)
        host.controller?.present(vc!, animated: true)
    }
}
