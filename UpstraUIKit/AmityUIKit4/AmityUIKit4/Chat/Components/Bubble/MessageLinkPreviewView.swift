//
//  MessageLinkPreviewView.swift
//  AmityUIKit4
//

import SwiftUI
import LinkPresentation

// MARK: - Detector

enum MessageLinkDetector {
    static func firstURL(in text: String) -> URL? {
        guard !text.isEmpty else { return nil }
        // Use the shared link detector so Chat and Social agree on what counts as a link.
        guard let urlString = AmityPreviewLinkWizard.shared.detectLinks(text: text).first else { return nil }
        guard var url = URL(string: urlString) else { return nil }
        if url.scheme == nil {
            url = URL(string: "https://\(urlString)") ?? url
        }
        return url
    }
}

// MARK: - Metadata cache

final class MessageLinkMetadataCache {
    static let shared = MessageLinkMetadataCache()
    private var store: [String: LPLinkMetadata] = [:]
    private var failed: Set<String> = []
    private var inFlight: Set<String> = []
    private let queue = DispatchQueue(label: "amity.chat.linkpreview.cache")

    func cached(for url: URL) -> LPLinkMetadata? {
        queue.sync { store[url.absoluteString] }
    }

    func didFail(for url: URL) -> Bool {
        queue.sync { failed.contains(url.absoluteString) }
    }

    func set(_ metadata: LPLinkMetadata, for url: URL) {
        queue.sync { store[url.absoluteString] = metadata }
    }

    func markFailed(for url: URL) {
        queue.sync { _ = failed.insert(url.absoluteString) }
    }

    func shouldFetch(for url: URL) -> Bool {
        queue.sync {
            let key = url.absoluteString
            guard store[key] == nil, !failed.contains(key), !inFlight.contains(key) else { return false }
            inFlight.insert(key)
            return true
        }
    }

    func finishedFetch(for url: URL) {
        queue.sync { _ = inFlight.remove(url.absoluteString) }
    }
}

// MARK: - View

struct MessageLinkPreviewView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let url: URL
    let isOwner: Bool

    @State private var metadata: LPLinkMetadata?
    @State private var thumbnail: UIImage?
    @State private var isLoading: Bool = true
    @State private var didFail: Bool = false

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
            } else if didFail || metadata == nil {
                fallback
            } else {
                content
            }
        }
        .frame(width: previewWidth, height: cardHeight, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .contentShape(Rectangle())
        .onTapGesture { open() }
        .onAppear(perform: load)
    }

    // MARK: Sections

    private var content: some View {
        HStack(spacing: 0) {
            imageSection
            textSection(title: metadata?.title, host: displayHost(url), background: cardBackground)
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
        if let thumb = thumbnail {
            Image(uiImage: thumb)
                .resizable()
                .scaledToFill()
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
        UIApplication.shared.open(url)
    }

    // MARK: Loading

    private func load() {
        if let cached = MessageLinkMetadataCache.shared.cached(for: url) {
            metadata = cached
            isLoading = false
            renderThumbnail(from: cached)
            return
        }
        if MessageLinkMetadataCache.shared.didFail(for: url) {
            didFail = true
            isLoading = false
            return
        }
        guard MessageLinkMetadataCache.shared.shouldFetch(for: url) else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { settleAfterSiblingFetch() }
            return
        }

        let provider = LPMetadataProvider()
        provider.timeout = 8
        provider.startFetchingMetadata(for: url) { meta, error in
            MessageLinkMetadataCache.shared.finishedFetch(for: url)
            if let meta, error == nil {
                MessageLinkMetadataCache.shared.set(meta, for: url)
                DispatchQueue.main.async {
                    self.metadata = meta
                    self.isLoading = false
                    self.renderThumbnail(from: meta)
                }
            } else {
                MessageLinkMetadataCache.shared.markFailed(for: url)
                DispatchQueue.main.async {
                    self.didFail = true
                    self.isLoading = false
                }
            }
        }
    }

    private func settleAfterSiblingFetch() {
        if let cached = MessageLinkMetadataCache.shared.cached(for: url) {
            self.metadata = cached
            self.isLoading = false
            self.renderThumbnail(from: cached)
        } else if MessageLinkMetadataCache.shared.didFail(for: url) {
            self.didFail = true
            self.isLoading = false
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { settleAfterSiblingFetch() }
        }
    }

    private func renderThumbnail(from meta: LPLinkMetadata) {
        let provider = meta.imageProvider ?? meta.iconProvider
        provider?.loadObject(ofClass: UIImage.self) { object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }
}
