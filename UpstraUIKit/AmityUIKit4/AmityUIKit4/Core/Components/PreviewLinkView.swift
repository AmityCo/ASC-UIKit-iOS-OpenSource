//
//  PreviewLinkView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/8/24.
//

import SwiftUI
import AmitySDK
import LinkPresentation

struct PreviewLinkView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: PreviewLinkViewModel
    
    init(post: AmityPostModel) {
        self._viewModel = StateObject(wrappedValue: PreviewLinkViewModel(post: post))
    }
    
    var body: some View {
        if let url = viewModel.previewLinkData.url {
            VStack(alignment: .leading, spacing: 0) {
                let fallbackImage = viewModel.previewLinkData.metadata == nil ? AmityIcon.previewLinkErrorIcon : AmityIcon.previewLinkDefaultIcon
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 210)
                    .overlay(
                        previewLinkImageView(viewModel.previewLinkData.image, fallback: fallbackImage.getImage() ?? UIImage())
                            .isHidden(!viewModel.previewLinkData.loaded)
                    )
                    .clipped()
                    .shimmering(active: !viewModel.previewLinkData.loaded)
                
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
                        let urlText = viewModel.previewLinkData.metadata?.url?.host ?? "Preview not available"
                        let titleText = viewModel.previewLinkData.metadata?.title ?? "Please make sure the URL is correct and try again."
                        let urlTextColor = viewModel.previewLinkData.metadata?.url?.host == nil ? Color(viewConfig.theme.baseColor) : Color(viewConfig.theme.baseColorShade1)
                        let urlTextStyle: AmityTextStyle = viewModel.previewLinkData.metadata?.url?.host == nil ? .bodyBold(urlTextColor) : .caption(urlTextColor)
                        let titleTextColor = viewModel.previewLinkData.metadata?.url?.host == nil ? Color(viewConfig.theme.baseColorShade1) : Color(viewConfig.theme.baseColor)
                        let titleTextStyle: AmityTextStyle = viewModel.previewLinkData.metadata?.url?.host == nil ? .body(titleTextColor) : .bodyBold(titleTextColor)
                        
                        Text(urlText)
                            .applyTextStyle(urlTextStyle)
                            .lineLimit(1)
                        
                        Text(titleText)
                            .applyTextStyle(titleTextStyle)
                            .lineLimit(2)
                    }
                }
                .padding([.leading, .trailing], 12)
                .padding([.bottom, .top], 14)
            }
            .cornerRadius(8.0)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.open(url)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(viewConfig.theme.baseColorShade3), lineWidth: 0.4)
            )
        }
    }
    
    @ViewBuilder
    private func previewLinkImageView(_ image: UIImage?, fallback: UIImage) -> some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Image(uiImage: fallback)
                .frame(width: 50, height: 50)
                .scaledToFit()
        }
    }
}

class PreviewLinkViewModel: ObservableObject {
    let post: AmityPostModel
    @Published var previewLinkData: (url: URL?, metadata: LPLinkMetadata?, image: UIImage?, loaded: Bool) = (nil, nil, nil, false)
    
    init(post: AmityPostModel) {
        self.post = post
        
        Task { @MainActor in
            await getPreviewlinkData()
        }
    }
    
    @MainActor
    private func getPreviewlinkData() async {
        let urls = AmityPreviewLinkWizard.shared.detectLinks(input: post.text)
        
        guard urls.count > 0 else {
            previewLinkData.url = nil
            return
        }
        
        previewLinkData.loaded = false
        previewLinkData.url = urls[0]
        previewLinkData.metadata = await AmityPreviewLinkWizard.shared.getMetadata(url: urls[0])
        previewLinkData.loaded = true
        
        previewLinkData.metadata?.imageProvider?.loadObject(ofClass: UIImage.self, completionHandler: { [weak self] image, error in
            guard let self else { return }
            
            DispatchQueue.main.async {
                if let image = image as? UIImage {
                    self.previewLinkData.image = image
                }
            }
        })
    }
}

