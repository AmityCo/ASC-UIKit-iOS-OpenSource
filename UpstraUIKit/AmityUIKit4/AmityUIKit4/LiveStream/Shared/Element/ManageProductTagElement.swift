//
//  ManageProductTagElement.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 16/2/2569 BE.
//

import SwiftUI
import AmitySDK
import SafariServices

// MARK: - ManageProductTagElement
struct ManageProductTagElement: AmityElementView {
    var pageId: PageId?
    var componentId: ComponentId?
    
    var id: ElementId {
        return .manageProductTagItem
    }
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    let product: AmityProduct
    let isPinned: Bool
    let renderMode: ManageProductTagRenderMode
    let onPin: (String) -> Void
    let onDelete: (String) -> Void

    @State private var thumbnailLoadFailed = false

    private var isInactive: Bool {
        return product.status != .active
    }
    
    private func handleProductClick() {
        if let url = URL(string: product.productUrl) {
            let browserVC = SFSafariViewController(url: url)
            browserVC.modalPresentationStyle = .pageSheet
            UIApplication.topViewController()?.present(browserVC, animated: true)
        }
    }
    
    private func formatPrice(_ product: AmityProduct) -> String {
        let price = product.price ?? 0
        let currencyCode = product.currency ?? ""

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = .current
       
        return formatter.string(from: NSNumber(value: price)) ?? "\(currencyCode) \(price)"
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Product Thumbnail with Pinned Overlay or Unavailable Overlay
            ZStack(alignment: .bottomLeading) {
                if let thumbnailUrl = product.thumbnailUrl, !thumbnailUrl.isEmpty, !thumbnailLoadFailed {
                    AsyncImage(placeholderView: {
                        Color(viewConfig.defaultDarkTheme.baseColorShade4)
                    }, url: URL(string: thumbnailUrl), contentMode: .fill)
                    .onLoaded { success in
                        if !success { thumbnailLoadFailed = true }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#292B32"), lineWidth: 1)
                    )
                    .onTapGesture {
                        if !isInactive {
                            handleProductClick()
                        }
                    }
                } else {
                    ZStack {
                        Color(viewConfig.defaultDarkTheme.baseColorShade4)
                        
                        Image(AmityIcon.LiveStream.productTagImagePlaceholderIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#292B32"), lineWidth: 1)
                    )
                    .onTapGesture {
                        if !isInactive {
                            handleProductClick()
                        }
                    }
                }
                
                // 50% black overlay for unavailable products
                if isInactive {
                    Color.black.opacity(0.5)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                HStack(spacing: 4) {
                    Image(AmityIcon.LiveStream.livestreamFilledPinProductIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundColor(.white)
                    
                    Text(AmityLocalizedStringSet.Social.productTagPinnedLabel.localizedString)
                        .applyTextStyle(.captionBold(.white))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(width: 100, alignment: .center)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.2)]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .isHidden(!(isPinned && renderMode == .livestream) )
                .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 0) {
                Text(AmityLocalizedStringSet.Social.productTagUnlistedLabel.localizedString)
                    .applyTextStyle(.caption(Color(viewConfig.defaultDarkTheme.baseColorShade2)))
                    .isHidden(!isInactive)
                
                Text(product.productName)
                    .applyTextStyle(.bodyBold(Color(isInactive ? viewConfig.defaultDarkTheme.baseColorShade4 : viewConfig.defaultDarkTheme.baseColor)))
                    .lineLimit(2)
                    .onTapGesture {
                        if !isInactive {
                            handleProductClick()
                        }
                    }
                
                Spacer(minLength: 8)
                
                // Price and Action Buttons on same line
                HStack(spacing: 0) {
                    if !isInactive, product.price != nil {
                        Text(formatPrice(product))
                            .applyTextStyle(.body(Color(viewConfig.defaultDarkTheme.baseColorShade3)))
                            
                    }
                    
                    Spacer()
                                        
                    // Delete Button - square icon button (always shown)
                    Button(action: { onDelete(product.productId) }) {
                        Image(AmityIcon.trashBinWhiteIcon.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(hex: "898E9E"), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 8)
                    
                    // Pin/Unpin Button - only in livestream mode and when available
                    if renderMode == .livestream && !isInactive {
                        Button(action: { onPin(product.productId) }) {
                            HStack(spacing: 6) {
                                Image(AmityIcon.LiveStream.livestreamPinProductIcon.imageResource)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.white)
                                
                                Text(isPinned ? AmityLocalizedStringSet.Social.productTagUnpinButton.localizedString : AmityLocalizedStringSet.Social.productTagPinButton.localizedString)
                                    .applyTextStyle(.bodyBold(.white))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .frame(height: 28)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(viewConfig.defaultDarkTheme.backgroundColor))
    }
}
