//
//  ManageProductTagListComponent.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 16/2/2569 BE.
//

import SwiftUI
import AmitySDK

// MARK: - ManageProductTagRenderMode
enum ManageProductTagRenderMode {
    /// Live broadcast context — shows pin/unpin controls
    case livestream
    /// Recorded playback context — flat list, no pin controls
    case playback
}

// MARK: - ManageProductTagListComponent
struct ManageProductTagListComponent: AmityComponentView {
    @EnvironmentObject var host: AmitySwiftUIHostWrapper

    var pageId: PageId?

    var id: ComponentId {
        .manageProductTagList
    }

    @StateObject private var viewConfig: AmityViewConfigController
    @ObservedObject private var viewModel: ManageProductTagViewModel
    
    private let renderMode: ManageProductTagRenderMode
    var canAddProducts: Bool = true
    private let onClose: ([AmityProduct]) -> Void
    private let onAddProducts: () -> Void
    private let onPinToggle: (String, Bool) -> Void
    private let onProductRemove: (String) -> Void
    
    init(
        pageId: PageId? = nil,
        viewModel: ManageProductTagViewModel? = nil,
        renderMode: ManageProductTagRenderMode = .livestream,
        onClose: @escaping ([AmityProduct]) -> Void = { _ in },
        onAddProducts: @escaping () -> Void = {},
        onPinToggle: @escaping (String, Bool) -> Void = { _, _ in },
        onProductRemove: @escaping (String) -> Void = { _ in }
    ) {
        self.pageId = pageId
        self._viewModel = ObservedObject(wrappedValue: viewModel ?? ManageProductTagViewModel())
        self.renderMode = renderMode
        self.onClose = onClose
        self.onAddProducts = onAddProducts
        self.onPinToggle = onPinToggle
        self.onProductRemove = onProductRemove
        self._viewConfig = StateObject(
            wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .manageProductTagList)
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            BottomSheetDragIndicator()
                .foregroundColor(Color(viewConfig.defaultDarkTheme.baseColorShade3))
                .padding(.top, 8)
            
            HStack {
                Spacer()
                    .frame(width: 24)
                    .padding(.leading, 16)
                
                Spacer()

                VStack(spacing: 4) {
                    Text(AmityLocalizedStringSet.Social.productTagTaggedProducts.localizedString)
                        .applyTextStyle(.titleBold(Color(viewConfig.defaultDarkTheme.baseColor)))

                    Text("\(viewModel.taggedProducts.count)/\(viewModel.maxProductCount)")
                        .applyTextStyle(.caption(Color(viewConfig.defaultDarkTheme.baseColorShade2)))
                }

                Spacer()
                
                Button(action: {
                    UIApplication.topViewController()?.dismiss(animated: true)
                    onClose(viewModel.taggedProducts)
                }) {
                    Image(AmityIcon.closeIcon.imageResource)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(viewConfig.defaultDarkTheme.baseColor))
                }
                .padding(.trailing, 16)
            }
            .padding(.vertical, 16)
            .background(Color(viewConfig.defaultDarkTheme.backgroundColor))
            
            Rectangle()
                .fill(Color(viewConfig.defaultDarkTheme.baseColorShade4))
                .frame(height: 1)
            
            if viewModel.taggedProducts.isEmpty {
                // Empty State
                VStack(spacing: 0) {
                    Spacer()
                    
                    Image(AmityIcon.LiveStream.emptyProductTaggingIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .padding(.bottom, 12)
                    
                    VStack(spacing: 4) {
                        Text(AmityLocalizedStringSet.Social.productTagNoProductsTitle.localizedString)
                            .applyTextStyle(.bodyBold(Color(viewConfig.defaultDarkTheme.baseColorShade2)))
                        
                        Text(AmityLocalizedStringSet.Social.productTagNoProductsMessage.localizedString)
                            .applyTextStyle(.body(Color(viewConfig.defaultDarkTheme.baseColorShade2)))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 16)
                    
                    if canAddProducts {
                        Button(action: {
                            onAddProducts()
                        }) {
                            Text(AmityLocalizedStringSet.Social.productTagAddProducts.localizedString)
                                .applyTextStyle(.bodyBold(.white))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            } else {
                // Product List
                ScrollView {
                    VStack(spacing: 0) {
                        
                        Spacer(minLength: 11)
                        if renderMode == .playback {
                            // Playback mode: flat list, no pinned section separation
                            ForEach(viewModel.taggedProducts, id: \.productId) { product in
                                ManageProductTagElement(
                                    product: product,
                                    isPinned: false,
                                    renderMode: renderMode,
                                    onPin: { productId in
                                        let wasPinned = viewModel.pinnedProductId == productId
                                        onPinToggle(productId, !wasPinned)
                                    },
                                    onDelete: { productId in
                                        onProductRemove(productId)
                                    }
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 5)
                            }
                        } else {
                            // Livestream mode: pinned section + other products section
                            // Pinned Product Section
                            if let pinnedId = viewModel.pinnedProductId, let pinnedProduct = viewModel.taggedProducts.first(where: { $0.productId == pinnedId }) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(AmityLocalizedStringSet.Social.productTagPinnedProductSection.localizedString)
                                        .applyTextStyle(.titleBold(Color(viewConfig.defaultDarkTheme.baseColor)))
                                        .padding(.horizontal, 16)
                                        .padding(.top, 11)
                                        .padding(.bottom, 14)

                                    ManageProductTagElement(
                                        product: pinnedProduct,
                                        isPinned: true,
                                        renderMode: renderMode,
                                        onPin: { productId in
                                            let wasPinned = viewModel.pinnedProductId == productId
                                            onPinToggle(productId, !wasPinned)
                                        },
                                        onDelete: { productId in
                                            onProductRemove(productId)
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }

                            // Other Products Section
                            if !viewModel.taggedProducts.filter({ $0.productId != viewModel.pinnedProductId }).isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(viewModel.pinnedProductId != nil ? AmityLocalizedStringSet.Social.productTagOtherProductsSection.localizedString : "")
                                        .applyTextStyle(.titleBold(Color(viewConfig.defaultDarkTheme.baseColor)))
                                        .isHidden(viewModel.pinnedProductId == nil)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 22)
                                        .padding(.bottom, 13)

                                    ForEach(viewModel.taggedProducts.filter { $0.productId != viewModel.pinnedProductId }, id: \.productId) { product in
                                        ManageProductTagElement(
                                            product: product,
                                            isPinned: false,
                                            renderMode: renderMode,
                                            onPin: { productId in
                                                onPinToggle(productId, true)
                                            },
                                            onDelete: { productId in
                                                onProductRemove(productId)
                                            }
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 5)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Bottom Button
                if canAddProducts {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(viewConfig.defaultDarkTheme.baseColorShade4))
                            .frame(height: 1)
                        
                        Button(action: {
                            onAddProducts()
                        }) {
                            Text(AmityLocalizedStringSet.Social.productTagAddProducts.localizedString)
                                .applyTextStyle(.bodyBold(viewModel.canAddMore() ? Color(viewConfig.defaultDarkTheme.baseColor) : Color(hex: "#40434E")))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(viewConfig.defaultDarkTheme.backgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(viewModel.canAddMore() ? Color(viewConfig.defaultDarkTheme.secondaryColor.blend(.shade3)) : Color(hex: "#292B32"), lineWidth: 1)
                                )
                        }
                        .disabled(!viewModel.canAddMore())
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                        .background(Color(viewConfig.defaultDarkTheme.backgroundColor))
                    }
                }
            }
        }
        .background(Color(viewConfig.defaultDarkTheme.backgroundColor))
        .ignoresSafeArea(edges: .bottom)
        .onDisappear {
            onClose(viewModel.taggedProducts)
        }
    }
}

// MARK: - ManageProductTagViewModel
class ManageProductTagViewModel: ObservableObject {
    @Published var taggedProducts: [AmityProduct] = []
    @Published var pinnedProductId: String?
    
    let maxProductCount = 20
    
    func togglePin(_ productId: String) {
        if pinnedProductId == productId {
            pinnedProductId = nil
        } else {
            pinnedProductId = productId
        }
    }
    
    func deleteProduct(_ productId: String) {
        taggedProducts.removeAll { $0.productId == productId }
        if pinnedProductId == productId {
            pinnedProductId = nil
        }
    }
    
    func canAddMore() -> Bool {
        return taggedProducts.count < maxProductCount
    }
}
