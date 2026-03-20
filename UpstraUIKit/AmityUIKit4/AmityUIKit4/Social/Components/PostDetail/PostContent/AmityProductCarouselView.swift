//
//  AmityProductCarouselView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/19/26.
//

import SwiftUI
import AmitySDK
import SafariServices

struct AmityProductCarouselView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController
    @EnvironmentObject var host: AmitySwiftUIHostWrapper

    let allProductTags: [AmityProductTagModel]
    let postId: String

    @State private var showProductList: Bool = false

    static var viewedProductIds = Set<String>()

    private let maxDisplayCount = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Products tagged")
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                .padding(.horizontal, 16)

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                Color.clear.frame(width: 4, height: 0)

                ForEach(allProductTags.prefix(maxDisplayCount), id: \.productId) { productTag in
                    ProductCarouselCardView(
                        productTag: productTag,
                        postId: postId,
                        viewConfig: viewConfig
                    )
                }

                if allProductTags.count > maxDisplayCount {
                    viewAllButton
                        .padding(.top, 82)
                }

                Color.clear.frame(width: 4, height: 0)
            }
        }
        .sheet(isPresented: $showProductList) {
            productTagListSheet
        }
        } // VStack
    }

    private var viewAllButton: some View {
        Button {
            showProductList = true
        } label: {
            Circle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                )
        }
    }

    @ViewBuilder
    private var productTagListSheet: some View {
        let component = AmityProductTagListComponent(
            productTags: allProductTags,
            renderMode: .post,
            sourceId: postId,
            onProductClick: { productTag in
                if let url = URL(string: productTag.object.productUrl) {
                    let browserVC = SFSafariViewController(url: url)
                    browserVC.modalPresentationStyle = .pageSheet
                    UIApplication.topViewController()?.present(browserVC, animated: true)
                }
            })
        component
            .environmentObject(host)
            .halfSheetPresentation()
    }
}

// MARK: - Product Carousel Skeleton

struct ProductCarouselSkeletonView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title placeholder
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 100, height: 8)
                .clipShape(RoundedCorner(radius: 12))
                .shimmering(gradient: shimmerGradient)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            // Card placeholders
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { _ in
                    productCardSkeleton
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }

    private var productCardSkeleton: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 100, height: 100)
                .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
                .shimmering(gradient: shimmerGradient)

            // Text placeholders
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(width: 70, height: 8)
                    .clipShape(RoundedCorner(radius: 12))
                    .shimmering(gradient: shimmerGradient)

                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(width: 40, height: 8)
                    .clipShape(RoundedCorner(radius: 12))
                    .shimmering(gradient: shimmerGradient)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
        .frame(width: 100)
    }
}

// MARK: - Product Carousel Card

private struct ProductCarouselCardView: View {
    let productTag: AmityProductTagModel
    let postId: String
    let viewConfig: AmityViewConfigController

    private var isUnavailable: Bool {
        return productTag.object.isDeleted || productTag.object.status == .archived
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail with overlay for unavailable products
            ZStack {
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

                if isUnavailable {
                    Color.white.opacity(0.8)
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                }
            }

            // Product detail
            if isUnavailable {
                Text("Unlisted")
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    .lineLimit(1)
                    .frame(width: 100, alignment: .leading)

                Text(productTag.object.productName)
                    .applyTextStyle(.custom(14, .semibold, Color(viewConfig.theme.baseColorShade4)))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: 100, alignment: .topLeading)
            } else {
                Text(productTag.object.productName)
                    .applyTextStyle(.custom(14, .semibold, Color(viewConfig.theme.baseColor)))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: 100, alignment: .topLeading)

                if let _ = productTag.object.price {
                    Text(formatPrice(productTag.object))
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                        .lineLimit(1)
                        .frame(width: 100, alignment: .leading)
                }
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isUnavailable else { return }
            trackProductClick()
            if let url = URL(string: productTag.object.productUrl) {
                let browserVC = SFSafariViewController(url: url)
                browserVC.modalPresentationStyle = .pageSheet
                UIApplication.topViewController()?.present(browserVC, animated: true)
            }
        }
        .background(GeometryReader { geometry in
            Color.clear
                .onChange(of: geometry.frame(in: .global)) { frame in
                    checkVisibilityAndTrackView(frame: frame)
                }
        })
    }

    // MARK: - Analytics

    private func trackProductView() {
        guard !AmityProductCarouselView.viewedProductIds.contains(productTag.productId) else { return }
        AmityProductCarouselView.viewedProductIds.insert(productTag.productId)

        let location = "*/post_content_component/*"
        productTag.object.analytics.markAsViewed(
            location: location,
            sourceType: .post,
            sourceId: postId
        )
    }

    private func trackProductClick() {
        let location = "*/post_content_component/*"
        productTag.object.analytics.markAsClicked(
            location: location,
            sourceType: .post,
            sourceId: postId
        )
    }

    private func checkVisibilityAndTrackView(frame: CGRect) {
        let screenHeight = UIScreen.main.bounds.height
        let visibleHeight = min(screenHeight, frame.maxY) - max(0, frame.minY)
        let visiblePercentage = (visibleHeight / frame.height) * 100

        if visiblePercentage > 60 && !AmityProductCarouselView.viewedProductIds.contains(productTag.productId) {
            trackProductView()
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
