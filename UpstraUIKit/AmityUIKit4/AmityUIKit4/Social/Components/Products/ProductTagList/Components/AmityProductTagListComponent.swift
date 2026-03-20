//
//  AmityProductTagListComponent.swift
//  AmityUIKit4
//
//  Created by Amity on 2026-01-14.
//

import SwiftUI
import AmitySDK

/// Render mode for ProductTagListComponent (v3)
/// Determines the context and behavior of the product tag list
public enum ProductTagListRenderMode: String {
    /// Post/feed context - standard interaction
    case post = "post"
    /// Livestream context - viewer browsing products
    case livestream = "livestream"
    /// Image attachment context - products in photo
    case image = "image"
    /// Video attachment context - products in video
    case video = "video"
}

/// A component that displays a vertical list of product tags.
/// Shows tagged products within post content or livestream context.
///
/// Component ID: `product_tag_list`
///
/// ## Usage
/// ```swift
/// // Post context (default)
/// AmityProductTagListComponent(
///     productTags: productTags,
///     renderMode: .post,
///     onProductClick: { productTag in
///         // Handle product click
///     }
/// )
///
/// // Livestream context
/// AmityProductTagListComponent(
///     productTags: productTags,
///     renderMode: .livestream,
///     onProductClick: { productTag in
///         // Handle product click
///     }
/// )
/// ```
public struct AmityProductTagListComponent: AmityComponentView {

    // MARK: - AmityComponentView

    public var pageId: PageId?

    public var id: ComponentId {
        .productTagListBottomsheet
    }

    // MARK: - Properties

    /// Array of product tags to display
    private let productTags: [AmityProductTagModel]

    /// Context mode for rendering (v2)
    private let renderMode: ProductTagListRenderMode

    /// ID of the pinned product (v2) - used to show pin banner
    private let pinnedProductId: String?
    
    /// Source ID for analytics (postId or roomId)
    private let sourceId: String

    /// Callback when user clicks on a product item
    private let onProductClick: ((AmityProductTagModel) -> Void)?

    /// Callback when close button is tapped
    private let onClose: (() -> Void)?

    @StateObject private var viewConfig: AmityViewConfigController

    // MARK: - Initialization

    /// Creates a new ProductTagListComponent
    /// - Parameters:
    ///   - pageId: Optional page ID for customization
    ///   - productTags: Array of product tags to display
    ///   - renderMode: Context mode for rendering (default: .post)
    ///   - pinnedProductId: Optional ID of pinned product to show pin banner (v2)
    ///   - sourceId: Source ID for analytics (postId or roomId)
    ///   - onClose: Optional callback when close button is tapped
    ///   - onProductClick: Optional callback when user clicks on a product item
    public init(
        pageId: PageId? = nil,
        productTags: [AmityProductTagModel],
        renderMode: ProductTagListRenderMode = .post,
        pinnedProductId: String? = nil,
        sourceId: String = "",
        onClose: (() -> Void)? = nil,
        onProductClick: ((AmityProductTagModel) -> Void)? = nil
    ) {
        self.pageId = pageId
        self.productTags = productTags
        self.renderMode = renderMode
        self.pinnedProductId = pinnedProductId
        self.sourceId = sourceId
        self.onClose = onClose
        self.onProductClick = onProductClick
        self._viewConfig = StateObject(
            wrappedValue: AmityViewConfigController(
                pageId: pageId,
                componentId: .productTagListBottomsheet
            )
        )
    }

    // MARK: - Body

    public var body: some View {
        // Hide component when no products tagged (REQ-003)
        if productTags.isEmpty {
            EmptyView()
        } else {
            productTagListContent
                .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
                .environmentObject(viewConfig)
        }
    }

    // MARK: - Private Views

    /// Main content view with header and product list
    private var productTagListContent: some View {
        VStack(spacing: 0) {
            // Drag indicator
            BottomSheetDragIndicator()
                .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                .padding(.top, 8)

            // Header with context-aware label (REQ-001, v2)
            AmityProductTagListHeaderElement(
                pageId: pageId,
                componentId: id,
                renderMode: renderMode,
                onClose: renderMode == .livestream ? onClose : nil
            )
            .environmentObject(viewConfig)
            .padding(.top, 16)
            .padding(.bottom, renderMode == .livestream ? 12 : 24)
            .padding(.horizontal, 16)

            if renderMode == .livestream {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
                    .padding(.bottom, 16)
            }

            // Vertical list of product tags (REQ-002)
            ScrollView {
                productListView
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Products tagged in this post")
    }

    /// Vertical list of product tag elements (REQ-002, REQ-006)
    private var productListView: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(productTags, id: \.productId) { productTag in
                let sourceType: AmityAnalyticsSourceType = renderMode == .livestream ? .room : .post
                AmityProductTagElement(
                    pageId: pageId,
                    componentId: id,
                    productTag: productTag,
                    renderMode: renderMode,
                    isPinned: productTag.productId == pinnedProductId,
                    onClick: {
                        onProductClick?(productTag)
                    },
                    sourceId: sourceId,
                    sourceType: sourceType
                )
                .environmentObject(viewConfig)
            }
        }
        .padding(.horizontal, 16)
        .accessibilityElement(children: .contain)
    }

}

// MARK: - Preview

#if DEBUG
struct AmityProductTagListComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // Preview with sample data would go here
            Text("ProductTagListComponent Preview")
        }
        .padding()
    }
}
#endif
