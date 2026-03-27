//
//  AmityProductTagElement.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/22/26.
//

import SwiftUI
import AmitySDK

/// ProductTagElement
/// Displays a single product tag with context-aware behavior and pin status.
/// Used within ProductTagListComponent to render individual product tags.
///
/// Element ID: `product_tag_list_item`
struct AmityProductTagElement: AmityElementView {

    var pageId: PageId?
    var componentId: ComponentId?

    var id: ElementId {
        return .productTagListItem
    }

    @EnvironmentObject var viewConfig: AmityViewConfigController

    /// The product tag data to display
    let productTag: AmityProductTagModel
    /// Context mode for rendering
    let renderMode: ProductTagListRenderMode
    var isPinned: Bool = false
    let onClick: () -> Void
    /// Source ID for analytics (postId or roomId)
    let sourceId: String
    /// Source type for analytics (room or post)
    let sourceType: AmityAnalyticsSourceType
    let viewedProductTracker: ViewedProductTracker
    
    /// Whether the product is unavailable (inactive)
    private var isInactive: Bool {
        return productTag.object.status != .active
    }
    
    // MARK: - Analytics Methods
    
    /// Track product view analytics when element becomes visible
    private func trackProductView() {
        let page = pageId?.rawValue ?? "*"
        let component = componentId?.rawValue ?? "*"
        let location = "\(page)/\(component)/\(id.rawValue)"
        
        guard !viewedProductTracker.hasViewed(productTag.productId) else {
            return
        }
        viewedProductTracker.markViewed(productTag.productId)
                
        productTag.object.analytics.markAsViewed(
            location: location,
            sourceType: sourceType,
            sourceId: sourceId
        )
    }
    
    /// Track product click analytics when user taps card
    private func trackProductClick() {
        let page = pageId?.rawValue ?? "*"
        let component = componentId?.rawValue ?? "*"
        let location = "\(page)/\(component)/\(id.rawValue)"
        
        productTag.object.analytics.markAsClicked(
            location: location,
            sourceType: sourceType,
            sourceId: sourceId
        )
    }
    
    /// Check if product card is 60% visible and track view
    private func checkVisibilityAndTrackView(frame: CGRect) {
        let screenHeight = UIScreen.main.bounds.height
        let visibleHeight = min(screenHeight, frame.maxY) - max(0, frame.minY)
        let visiblePercentage = (visibleHeight / frame.height) * 100
        
        if visiblePercentage > 60 {
            trackProductView()
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                AsyncImage(
                    placeholderView: {
                        ZStack {
                            Color(viewConfig.theme.baseColorShade4)
                            Image(AmityIcon.LiveStream.productTagImagePlaceholderIcon.imageResource)
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                                .frame(width: 36, height: 36)
                        }
                    },
                    url: URL(string: productTag.object.thumbnailUrl ?? ""),
                    contentMode: .fill
                )
                .frame(width: 100, height: 100)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
                )
                
                // 50% black overlay for unavailable products
                if isInactive {
                    Color.white.opacity(0.8)
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                }

                // Pin Status Banner (v2) - only for available products
                HStack(spacing: 4) {
                    Image(AmityIcon.LiveStream.livestreamFilledPinProductIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 9, height: 9)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                    
                    Text("Pinned")
                        .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColor)))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(width: 100, alignment: .center)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.8),
                            Color.black.opacity(0.2)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
                .isHidden(!(isPinned && true && renderMode == .livestream))
            }

            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                // Unlisted label - only when inactive
                Text("Unlisted")
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    .isHidden(!isInactive)
                
                // Product Name
                Text(productTag.object.productName)
                    .applyTextStyle(.bodyBold(Color(isInactive ? viewConfig.theme.baseColorShade4 : viewConfig.theme.baseColor)))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Use spacer to push price and button to bottom in livestream mode
                if renderMode == .livestream {
                    Spacer(minLength: 8)
                }

                // Price + Action Button Row
                HStack(spacing: 8) {
                    // Product Price - hidden when inactive
                    if !isInactive, let price = productTag.object.price, price > 0 {
                        Text(formatPrice(productTag.object))
                            .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade3)))
                    }
                    
                    Spacer()
                    
                    // View Button (v2) - shown in livestream mode
                    if renderMode == .livestream {
                        Text("View")
                            .applyTextStyle(.captionBold(.white))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .frame(width: 64, height: 28)
                            .background(Color(viewConfig.theme.primaryColor))
                            .cornerRadius(6)
                            .opacity(isInactive ? 0.5 : 1.0)
                    }
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isInactive else { return }
            trackProductClick()
            onClick()
        }
        .background(GeometryReader { geometry in
            Color.clear
                .onAppear {
                    checkVisibilityAndTrackView(frame: geometry.frame(in: .global))
                }
                .onChange(of: geometry.frame(in: .global)) { frame in
                    checkVisibilityAndTrackView(frame: frame)
                }
        })
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    /// Accessibility label including pin status
    private var accessibilityLabel: String {
        let name = productTag.object.productName
        let priceText = formatPrice(productTag.object)
        if true {
            return "\(name) - \(priceText) - Pinned"
        } else {
            return "\(name) - \(priceText)"
        }
    }

    // MARK: - Helpers

    private func formatPrice(_ product: AmityProduct) -> String {
        let price = product.price ?? 0
        let currencyCode = product.currency ?? ""

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = .current
       
        return formatter.string(from: NSNumber(value: price)) ?? "\(currencyCode) \(price)"
    }
}
