//
//  PreviewLinkView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/8/24.
//

import SwiftUI
import AmitySDK
import LinkPresentation
import UniformTypeIdentifiers

struct PreviewLinkView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: PreviewLinkViewModel
    
    init(viewModel: PreviewLinkViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    init(post: AmityPostModel) {
        self._viewModel = StateObject(wrappedValue: PreviewLinkViewModel(post: post))
    }
        
    var body: some View {
        if let url = viewModel.previewLinkData.url {
            VStack(alignment: .leading, spacing: 0) {
                
                if viewModel.previewLinkData.imageUrl != nil {
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 170)
                        .overlay(
                            previewLinkImageView(viewModel.previewLinkData.imageUrl)
                                .isHidden(!viewModel.previewLinkData.loaded)
                        )
                        .clipped()
                        .shimmering(active: !viewModel.previewLinkData.loaded)
                }
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
                
                VStack(alignment: .leading, spacing: 4) {
                    if !viewModel.previewLinkData.loaded {
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(width: 180, height: 10)
                            .clipShape(RoundedCorner())
                            .shimmering()
                        
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(width: 160, height: 10)
                            .clipShape(RoundedCorner())
                            .shimmering()
                    } else {
                        let defaultHost = viewModel.previewLinkData.defaultHost
                        let titleText = viewModel.previewLinkData.title ?? defaultHost
                        let urlText = viewModel.previewLinkData.domain ?? defaultHost
                        
                        Text(titleText)
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                            .lineLimit(2)
                        
                        Text(urlText)
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
            }
            .cornerRadius(8.0)
            .contentShape(Rectangle())
            .onTapGesture {
                guard UIApplication.shared.canOpenURL(url) else { return }
                
                UIApplication.shared.open(url)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    private func previewLinkImageView(_ imageURL: URL?) -> some View {
        if let imageURL {
            AsyncImage(placeholder: AmityIcon.previewLinkDefaultIcon.imageResource, url: imageURL)
                .frame(height: 170)
                .scaledToFill()
        }
    }
}

class PreviewLinkViewModel: ObservableObject {
    
    struct PreviewData {
        var title: String?
        var domain: String?
        var imageUrl: URL?
        var url: URL?
        var loaded: Bool
        
        var defaultHost: String {
            let defaultValue = url?.absoluteString ?? "-"
            
            if let url, !url.absoluteString.hasPrefix("http") {
                let newURL = "https://\(url.absoluteString)"
                return URL(string: newURL)?.host ?? defaultValue
            }
            
            return defaultValue
        }
    }
    
    var text: String
    
    @Published var previewLinkData: PreviewData = PreviewData(loaded: false)
    
    init(text: String) {
        self.text = text
        
        Task { @MainActor in
            await getPreviewlinkData()
        }
    }
    
    convenience init(post: AmityPostModel) {
        // For old posts which has link in their text content, but do not contain dedicated [AmityLink] payload, we will extract & highlight it again.
        guard !post.links.isEmpty else {
            self.init(text: post.text)
            return
        }
        
        // If post has links, highlight only if renderPreview is true
        if let firstLink = post.links.first, firstLink.renderPreview {
            self.init(text: firstLink.url)
        } else {
            // No need to show preview in this case.
            self.init(text: "")
        }
    }
    
    @MainActor
    func getPreviewlinkData() async {
        guard !text.isEmpty else { return }
        
        let urls = AmityPreviewLinkWizard.shared.detectLinks(text: text)
        
        guard urls.count > 0, let linkUrl = URL(string: urls[0]) else {
            previewLinkData.url = nil
            return
        }
                
        previewLinkData.loaded = false
        previewLinkData.url = linkUrl
        
        let metadata = await AmityPreviewLinkWizard.shared.fetchLinkMetadata(url: urls[0])
        
        let finalData = PreviewData(title: metadata?.title, domain: metadata?.domain, imageUrl: URL(string: metadata?.imageUrl ?? ""), url: linkUrl, loaded: true)
        previewLinkData = finalData
    }
}
