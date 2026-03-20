//
//  LivestreamPinnedProductElement.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 16/2/2569 BE.
//

import SwiftUI
import AmitySDK

// MARK: - LivestreamPinnedProductElement

/// Element that displays a pinned product card above the composer bar in livestream
/// Shows product information with unpin button (for hosts) or close button (for viewers)
/// 
/// Element ID: `livestream_pinned_product`
/// Pages: createLivestreamPage, livestreamPlayerPage
struct LivestreamPinnedProductElement: AmityElementView {
    
    var pageId: PageId?
    var componentId: ComponentId?
    
    var id: ElementId {
        return .livestreamPinnedProduct
    }
    
    // MARK: - Properties
    
    /// The pinned product to display
    let product: AmityProduct
    
    /// Whether current user can manage (unpin) the product
    /// true for host/co-host (shows unpin button), false for viewer (shows close button)
    let canManageProduct: Bool
    
    /// Called when user taps product card to open URL
    let onProductTap: (AmityProduct, String) -> Void
    
    /// Called when host unpins product (removes for everyone)
    let onUnpin: (AmityProduct) -> Void
    
    /// Called when viewer closes/dismisses card (hides for self only)
    let onDismiss: (AmityProduct) -> Void
    
    /// Called when host deletes an archived/inactive product from the list
    let onDelete: (AmityProduct) -> Void
    
    /// The current room ID for analytics
    var roomId: String? = nil
    
    // Static set for session-level view deduplication
    private static var viewedProductIds = Set<String>()
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    // MARK: - Analytics Methods
    
    private func formatPrice(_ product: AmityProduct) -> String {
        let price = product.price ?? 0
        let currencyCode = product.currency ?? ""

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = .current
       
        return formatter.string(from: NSNumber(value: price)) ?? "\(currencyCode) \(price)"
    }
    
    /// Track product view analytics when element becomes visible
    private func trackProductView() {
        guard !Self.viewedProductIds.contains(product.productId) else {
            return
        }
        Self.viewedProductIds.insert(product.productId)
        
        let component = componentId?.rawValue ?? "*"
        let location = "\(pageId?.rawValue ?? "")/\(component)/\(id.rawValue)"
        let resolvedRoomId = roomId ?? ""
        
        product.analytics.markAsViewed(
            location: location,
            sourceType: AmityAnalyticsSourceType.room,
            sourceId: resolvedRoomId
        )
    }
    
    /// Track product click analytics when user taps card
    private func trackProductClick() {
        let component = componentId?.rawValue ?? "*"
        let location = "\(pageId?.rawValue ?? "")/\(component)/\(id.rawValue)"
        let resolvedRoomId = roomId ?? ""
        
        product.analytics.markAsClicked(
            location: location,
            sourceType: AmityAnalyticsSourceType.room,
            sourceId: resolvedRoomId
        )
    }
    
    /// Check if product card is 60% visible and track view
    private func checkVisibilityAndTrackView(frame: CGRect) {
        let screenHeight = UIScreen.main.bounds.height
        let visibleHeight = min(screenHeight, frame.maxY) - max(0, frame.minY)
        let visiblePercentage = (visibleHeight / frame.height) * 100
        
        if visiblePercentage > 60 && !Self.viewedProductIds.contains(product.productId) {
            trackProductView()
        }
    }
    
    // MARK: - Body
    
    /// Whether the product is unavailable (inactive)
    private var isInactive: Bool {
        return product.status != .active
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 6) {
                // Product Thumbnail
                ZStack {
                    AsyncImage(placeholderView: {
                        Color(viewConfig.theme.baseColor)
                    }, url: URL(string: product.thumbnailUrl ?? ""), contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    // 80% white overlay for unavailable products
                    if isInactive {
                        Color.white.opacity(0.8)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                
                // Product Info
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(product.productName)
                            .applyTextStyle(.captionBold(Color(isInactive ? viewConfig.defaultDarkTheme.baseColorShade1 : viewConfig.defaultDarkTheme.baseColorShade4)))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        HStack(spacing: 0) {
                            if isInactive {
                                Text("Unlisted")
                                    .applyTextStyle(.caption(Color(viewConfig.defaultDarkTheme.baseColorShade2)))
                            } else if product.price != nil {
                                Text(formatPrice(product))
                                    .applyTextStyle(.caption(Color(viewConfig.defaultDarkTheme.baseColorShade2)))
                            }
                            
                            Spacer(minLength: 8)
                            
                            // Action Button
                            if isInactive && canManageProduct {
                                // Trash icon for host when product is inactive
                                Button(action: { onDelete(product) }) {
                                    Image(AmityIcon.trashBinWhiteIcon.imageResource)
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(Color(viewConfig.defaultDarkTheme.secondaryColor))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color(hex: "A5A9B5"), lineWidth: 1)
                                        )
                                }
                            } else if !isInactive && canManageProduct {
                                // Unpin button for host/co-host
                                Button(action: {
                                    onUnpin(product)
                                }) {
                                    HStack(spacing: 6) {
                                        Image(AmityIcon.LiveStream.livestreamPinProductIcon.imageResource)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(Color(viewConfig.defaultDarkTheme.secondaryColor))
                                        
                                        Text("Unpin")
                                            .applyTextStyle(.captionBold(Color(viewConfig.defaultDarkTheme.secondaryColor)))
                                    }
                                    .frame(height: 28)
                                    .padding(.horizontal, 8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color(viewConfig.defaultDarkTheme.baseColorShade3), lineWidth: 1)
                                    )
                                }
                            } else {
                                // Viewer: View button — 50% opacity when inactive
                                Text("View")
                                    .applyTextStyle(.captionBold(.white))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color(viewConfig.defaultDarkTheme.primaryColor))
                                    .cornerRadius(6)
                                    .opacity(isInactive ? 0.5 : 1.0)
                            }
                        }
                    }
                    .frame(height: 56)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.8))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                if !isInactive && !product.productUrl.isEmpty {
                    trackProductClick()
                    onProductTap(product, product.productUrl)
                }
            }
            .background(GeometryReader { geometry in
                Color.clear
                    .onChange(of: geometry.frame(in: .global)) { frame in
                        checkVisibilityAndTrackView(frame: frame)
                    }
            })
            
            // Close/Dismiss button (top-right corner, outside the card)
            // Only show for available products when viewer (not host/co-host)
            if !canManageProduct && !isInactive {
                Button(action: {
                    onDismiss(product)
                }) {
                    Image(AmityIcon.closeIcon.imageResource)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .offset(x: 8, y: -8)
            }
        }
    }
}
