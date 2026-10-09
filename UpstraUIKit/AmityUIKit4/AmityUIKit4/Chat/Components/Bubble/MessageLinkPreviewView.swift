//
//  MessageLinkPreviewView.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

// MARK: - Detector

struct MessageLink: Equatable {
    /// The link as detected in the text; the key Social uses to fetch and cache preview metadata.
    let raw: String
    /// `raw` with a scheme added when it has none, so it can be opened.
    let url: URL
}

enum MessageLinkDetector {
    static func firstLink(in text: String) -> MessageLink? {
        guard !text.isEmpty else { return nil }
        // Use the shared link detector so Chat and Social agree on what counts as a link.
        guard let urlString = AmityPreviewLinkWizard.shared.detectLinks(text: text).first else { return nil }
        guard var url = URL(string: urlString) else { return nil }
        if url.scheme == nil {
            url = URL(string: "https://\(urlString)") ?? url
        }
        return MessageLink(raw: urlString, url: url)
    }
}

// MARK: - View

struct MessageLinkPreviewView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let link: MessageLink
    let isOwner: Bool

    @State private var metadata: AmityLinkPreviewMetadata?
    @State private var isLoading: Bool = true
    @State private var didImageFail: Bool = false

    // Layout
    private var previewWidth: CGFloat {
        UIScreen.main.bounds.width * 0.6
    }
    private var imageWidth: CGFloat { previewWidth * 0.5 }
    private var cardHeight: CGFloat { imageWidth }
    private let cornerRadius: CGFloat = 10

    // Colors
    private var cardBackground: Color { Color(viewConfig.color(.surfaceCardPreviewLinkDefault)) }
    private var unavailableBackground: Color { Color(viewConfig.color(.surfaceCardPreviewLinkUnavailable)) }
    private var loadedImageBackground: Color { Color(viewConfig.color(.surfaceMediaImageLoaded)) }
    private var brokenImageBackground: Color { Color(viewConfig.color(.surfaceMediaImageBroken)) }
    private var titleColor: Color { Color(viewConfig.color(.textCardPreviewLinkTitleDefault)) }
    private var hostColor: Color { Color(viewConfig.color(.textCardPreviewLinkDomainDefault)) }
    private var errorIconColor: Color { Color(viewConfig.color(.iconMediaImageBroken)) }

    var body: some View {
        Group {
            if isLoading {
                skeleton
            } else if metadata == nil {
                fallback
            } else {
                content
            }
        }
        .frame(width: previewWidth, height: cardHeight, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .contentShape(Rectangle())
        .onTapGesture { open() }
        .onAppear { Task { await load() } }
    }

    // MARK: Sections

    private var content: some View {
        HStack(spacing: 0) {
            imageSection
            textSection(title: metadata?.title, host: metadata?.domain ?? displayHost(link.url), background: cardBackground)
        }
    }

    private var fallback: some View {
        HStack(spacing: 0) {
            errorImageSection
            textSection(
                title: AmityLocalizedStringSet.Chat.Bubble.linkPreviewUnavailable.localizedString,
                host: AmityLocalizedStringSet.Chat.Bubble.linkPreviewNoData.localizedString,
                background: unavailableBackground
            )
        }
    }

    private var skeleton: some View {
        HStack(spacing: 0) {
            // Image side: media-loading surface with the DS upload spinner (indeterminate).
            ZStack {
                Color(viewConfig.color(.surfaceMediaImageLoading))
                AmityLoader(variant: .uploadSpinner, size: .medium, viewConfig: viewConfig)
            }
            .frame(width: imageWidth, height: cardHeight)

            // Info side: preview-link skeleton surface with two placeholder bars.
            ZStack {
                Color(viewConfig.color(.surfaceCardPreviewLinkSkeleton))
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                        .frame(width: 80, height: 8)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                        .frame(width: 54, height: 8)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: cardHeight)
        }
    }

    // MARK: Building blocks

    @ViewBuilder
    private var imageSection: some View {
        if let imageUrl = URL(string: metadata?.imageUrl ?? ""), !didImageFail {
            AsyncImage(placeholderView: { loadedImageBackground }, url: imageUrl)
                .onLoaded { success in
                    if !success { didImageFail = true }
                }
                .frame(width: imageWidth, height: cardHeight)
                .clipped()
                .background(loadedImageBackground)
        } else {
            errorImageSection
        }
    }

    private var errorImageSection: some View {
        ZStack {
            Rectangle().fill(brokenImageBackground)
            Image(AmityIcon.DesignSystem.imageSlashR.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(errorIconColor)
        }
        .frame(width: imageWidth, height: cardHeight)
    }

    @ViewBuilder
    private func textSection(title: String?, host: String, background: Color) -> some View {
        ZStack {
            Rectangle().fill(background)
            VStack(alignment: .leading, spacing: 2) {
                if let title, !title.isEmpty {
                    Text(title)
                        .applyTextStyle(.captionBold(titleColor))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                Text(host)
                    .applyTextStyle(.captionSmall(hostColor))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: cardHeight)
    }

    // MARK: Helpers

    private func displayHost(_ url: URL) -> String {
        var host = url.host ?? url.absoluteString
        if host.hasPrefix("www.") { host = String(host.dropFirst(4)) }
        return host
    }

    private func open() {
        UIApplication.shared.open(link.url)
    }

    // MARK: Loading

    @MainActor
    private func load() async {
        metadata = await AmityPreviewLinkWizard.shared.fetchLinkMetadata(url: link.raw)
        didImageFail = false
        isLoading = false
    }
}
