//
//  AmityProductTagSelectionComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/13/26.
//

import SwiftUI
import AmitySDK
import Combine

public enum AmityProductTagSelectionMode {
    case create
    case edit
    case livestream
}

public struct AmityProductTagSelectionComponent: AmityComponentView {

    public var id: ComponentId {
        .productTagSelectionBottomsheet
    }

    public var pageId: PageId?

    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: ProductTagSelectionViewModel
    @State private var searchText: String = ""
    @State private var showDiscardAlert: Bool = false
    @State private var keyboardHeight: CGFloat = 0

    private let mode: AmityProductTagSelectionMode
    private let initialSelection: [AmityProduct]
    private let existingProducts: [String]
    private let onClose: () -> Void
    private let onDone: () -> Void
    private let onTagChanges: ([AmityProduct]) -> Void

    public init(
        pageId: PageId? = nil,
        mode: AmityProductTagSelectionMode = .create,
        initialSelection: [AmityProduct] = [],
        existingProducts: [String] = [],
        onClose: @escaping () -> Void = {},
        onDone: @escaping () -> Void = {},
        onTagChanges: @escaping ([AmityProduct]) -> Void = { _ in }
    ) {
        self.pageId = pageId
        self.mode = mode
        self.initialSelection = initialSelection
        self.existingProducts = existingProducts
        self.onClose = onClose
        self.onDone = onDone
        self.onTagChanges = onTagChanges
        self._viewConfig = StateObject(
            wrappedValue: AmityViewConfigController(
                pageId: pageId,
                componentId: .productTagSelectionBottomsheet))
        self._viewModel = StateObject(
            wrappedValue: ProductTagSelectionViewModel(
                initialSelection: initialSelection,
                existingProducts: existingProducts,
                mode: mode
            )
        )
    }

    private var isDoneEnabled: Bool {
        switch mode {
        case .create:
            return !viewModel.selectedProducts.isEmpty
        case .edit:
            return viewModel.hasSelectionChanged
        case .livestream:
            return viewModel.hasSelectionChanged
        }
    }

    private func handleClose() {
        // Show discard alert if there are unsaved changes
        if viewModel.hasSelectionChanged {
            showDiscardAlert = true
        } else {
            onClose()
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            BottomSheetDragIndicator()
                .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                .padding(.top, 8)
            
            // Header Element
            AmityProductTagSelectionHeaderElement(
                pageId: pageId,
                componentId: id,
                mode: mode,
                selectedCount: viewModel.selectedProducts.count,
                maxCount: viewModel.maxSelectionLimit,
                isDoneEnabled: isDoneEnabled,
                onClose: handleClose,
                onDone: onDone
            )
            .environmentObject(viewConfig)
            .alert(isPresented: $showDiscardAlert) {
                Alert(
                    title: Text(mode == .livestream ? "Discard product selection?" : "Discard product tags"),
                    message: Text(mode == .livestream ? "You have products selected that haven't been added yet. If you close now, your selection will be lost." : "You have tagged products that haven't been saved yet. If you leave now, your changes will be lost."),
                    primaryButton: .cancel(Text("Keep editing")),
                    secondaryButton: .destructive(Text("Discard")) {
                        onClose()
                    }
                )
            }

            Divider()
                .background(Color(viewConfig.theme.baseColorShade4))

            // Tagged products section
            if !viewModel.selectedProducts.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Tagged products")
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            Color.clear.frame(width: 4, height: 0)

                            ForEach(viewModel.selectedProducts, id: \.productId) { product in
                                TaggedProductView(
                                    product: product,
                                    onRemove: {
                                        viewModel.toggleSelection(product)
                                        if mode != .livestream {
                                            onTagChanges(viewModel.selectedProducts)
                                        }
                                    }
                                )
                                .environmentObject(viewConfig)
                            }

                            Color.clear.frame(width: 4, height: 0)
                        }
                    }
                }
                .background(Color(viewConfig.theme.backgroundColor))
            }

            Divider()
                .background(Color(viewConfig.theme.baseColorShade4))

            // Search Bar Element
            AmityProductTagSelectionSearchBarElement(
                pageId: pageId,
                componentId: id,
                searchText: $searchText
            )
            .onChange(of: searchText) { newValue in
                viewModel.searchKeyword = newValue
            }

            // Product list
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if viewModel.searchKeyword.count < 2 {
                            AmityProductTagEmptyElement(
                                pageId: pageId,
                                componentId: id
                            )
                            .padding(.top, keyboardHeight > 0 ? 76 : 150)
                        } else if viewModel.loadingStatus == .loading && viewModel.products.isEmpty {
                            // Loading state
                            ForEach(0..<5, id: \.self) { _ in
                                ProductItemSkeletonView()
                            }
                        } else if viewModel.products.isEmpty {
                            // No results state - search returned no matches
                            AmityProductTagNoResultElement(
                                pageId: pageId,
                                componentId: id
                            )
                            .padding(.top, 150)
                        } else {
                            // Results state
                            ForEach(Array(viewModel.products.enumerated()), id: \.element.productId) { index, product in
                                AmityProductTagSelectionItemElement(
                                    pageId: pageId,
                                    componentId: id,
                                    product: product,
                                    isSelected: viewModel.isExistingProduct(product) || viewModel.isSelected(product),
                                    isDisabled: viewModel.isProductDisabled(product),
                                    onTap: {
                                        viewModel.toggleSelection(product)
                                        if mode != .livestream {
                                            onTagChanges(viewModel.selectedProducts)
                                        }
                                    },
                                    isLivestream: mode == .livestream
                                )
                                .onAppear {
                                    if index == viewModel.products.count - 1 {
                                        viewModel.loadMore()
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Bottom Button (only for livestream mode)
                if mode == .livestream {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(height: 1)
                        
                        let disableButton = !isDoneEnabled || viewModel.selectedProducts.isEmpty
                        Button(action: {
                            
                            if mode == .livestream {
                                onTagChanges(viewModel.selectedProducts)
                            }
                            onDone()
                        }) {
                            Text("Add products")
                                .applyTextStyle(.bodyBold(.white))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(viewConfig.theme.primaryColor))
                                .cornerRadius(8)
                        }
                        .disabled(disableButton)
                        .opacity(disableButton ? 0.3 : 1.0)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                        .background(Color(viewConfig.theme.backgroundColor))
                    }
//                    .offset(y: keyboardHeight > 0 ? -keyboardHeight : 0)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(keyboardPublisher) { event in
            keyboardHeight = event.height
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .background(
            ModalDismissInterceptor(
                isModalInPresentation: viewModel.hasSelectionChanged,
                onDismissAttempted: { showDiscardAlert = true }
            )
            .frame(width: 0, height: 0)
        )
        .updateTheme(with: viewConfig)
    }
}

// MARK: - Modal Dismiss Interceptor
/// Intercepts swipe-to-dismiss on a UIKit-presented sheet so we can show
/// the discard alert under the same condition as the close button.
private struct ModalDismissInterceptor: UIViewControllerRepresentable {
    let isModalInPresentation: Bool
    let onDismissAttempted: () -> Void

    func makeUIViewController(context: Context) -> PresentationDismissHandler {
        let vc = PresentationDismissHandler()
        vc.onDismissAttempted = onDismissAttempted
        return vc
    }

    func updateUIViewController(_ uiViewController: PresentationDismissHandler, context: Context) {
        uiViewController.onDismissAttempted = onDismissAttempted
        // parent == the AmitySwiftUIHostingController that presents this sheet
        guard let parent = uiViewController.parent else { return }
        parent.isModalInPresentation = isModalInPresentation
        parent.presentationController?.delegate = uiViewController
    }
}

// MARK: - Tagged Product View
struct TaggedProductView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController

    let product: AmityProduct
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(placeholderView: {
                    ZStack {
                        Color(viewConfig.theme.baseColorShade4)
                        Image(AmityIcon.LiveStream.productTagImagePlaceholderIcon.imageResource)
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                            .frame(width: 28, height: 28)
                    }
                }, url: URL(string: product.thumbnailUrl ?? ""), contentMode: .fill)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
                )

                Button(action: onRemove) {
                    Image(AmityIcon.backgroundedCloseIcon.getImageResource())
                        .resizable()
                        .scaledToFill()
                        .frame(size: CGSize(width: 24, height: 24))
                }
                .offset(x: 8, y: -8)
            }

            Text(product.productName)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(2)
                .frame(width: 80)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Skeleton View
struct ProductItemSkeletonView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 80, height: 80)
                .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .bottomLeft]))

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 12)
                .frame(width: 200)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 80)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - View Model
class ProductTagSelectionViewModel: ObservableObject {
    private let productManager = ProductManager()
    private var productCollection: AmityCollection<AmityProduct>?
    private var collectionCancellables = Set<AnyCancellable>()
    private var searchCancellable: AnyCancellable? = nil
    private let initialSelection: [AmityProduct]
    private let existingProducts: Set<String>
    private let mode: AmityProductTagSelectionMode

    @Published var searchKeyword: String = ""
    @Published var products: [AmityProduct] = []
    @Published var selectedProducts: [AmityProduct] = []
    @Published var loadingStatus: AmityLoadingStatus = .notLoading

    var maxSelectionLimit: Int {
        switch mode {
        case .create, .edit:
            return min(5, 20 - existingProducts.count + initialSelection.count)
        case .livestream:
            return 20 - existingProducts.count
        }
    }

    var hasSelectionChanged: Bool {
        let initialIds = Set(initialSelection.map { $0.productId })
        let currentIds = Set(selectedProducts.map { $0.productId })
        return initialIds != currentIds
    }

    init(initialSelection: [AmityProduct] = [], existingProducts: [String] = [], mode: AmityProductTagSelectionMode = .create) {
        self.initialSelection = initialSelection
        self.existingProducts = Set(existingProducts)
        self.mode = mode
        self.selectedProducts = initialSelection

        searchCancellable = $searchKeyword
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] keyword in
                guard let self else { return }
                self.searchProducts(keyword)
            }
    }

    private func searchProducts(_ keyword: String) {
        guard keyword.count >= 2 else {
            products = []
            collectionCancellables.removeAll()
            productCollection = nil
            return
        }
        
        // Cancel previous subscriptions
        collectionCancellables.removeAll()
        
        let queryOptions = AmityProductQueryOptions(keyword: keyword, isActive: true, isDeleted: false)
        
        productCollection = productManager.searchProducts(queryOptions)

        productCollection?.$snapshots
            .sink { [weak self] products in
                self?.products = products
            }
            .store(in: &collectionCancellables)

        productCollection?.$loadingStatus
            .sink { [weak self] status in
                self?.loadingStatus = status
            }
            .store(in: &collectionCancellables)
    }

    func loadMore() {
        guard let productCollection, productCollection.hasNext else { return }
        productCollection.nextPage()
    }

    func toggleSelection(_ product: AmityProduct) {
        if let index = selectedProducts.firstIndex(where: { $0.productId == product.productId }) {
            selectedProducts.remove(at: index)
        } else {
            if selectedProducts.count < maxSelectionLimit {
                selectedProducts.append(product)
            }
        }
    }

    func isSelected(_ product: AmityProduct) -> Bool {
        selectedProducts.contains(where: { $0.productId == product.productId })
    }

    func canSelectMore() -> Bool {
        selectedProducts.count < maxSelectionLimit
    }
    
    func isExistingProduct(_ product: AmityProduct) -> Bool {
        existingProducts.contains(product.productId)
    }

    func isProductDisabled(_ product: AmityProduct) -> Bool {
        // Product is disabled if it's in existingProducts OR if selection limit is reached and it's not selected
        let isExisting = existingProducts.contains(product.productId)
        let isLimitReachedAndNotSelected = !isSelected(product) && !canSelectMore()
        return isExisting || isLimitReachedAndNotSelected
    }
}
