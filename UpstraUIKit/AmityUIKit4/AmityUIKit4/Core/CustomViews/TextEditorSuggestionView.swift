//
//  TextEditorSuggestionView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/15/26.
//

import SwiftUI
import AmitySDK
import Combine

public enum TextEditorSuggestionTab: Int, CaseIterable {
    case user = 0
    case product = 1
}

// MARK: - ViewModel
public class TextEditorSuggestionViewModel: ObservableObject {
    private let userManager = UserManager()
    private let productManager = ProductManager()

    private var userCollection: AmityCollection<AmityUser>?
    private var productCollection: AmityCollection<AmityProduct>?

    private var userCancellables = Set<AnyCancellable>()
    private var productCancellables = Set<AnyCancellable>()
    private var searchCancellable: AnyCancellable?

    @Published public var selectedTab: TextEditorSuggestionTab = .user
    @Published public var searchKeyword: String = ""
    @Published public var users: [AmityMentionUserModel] = []
    @Published public var products: [AmityProduct] = []
    @Published public var userLoadingStatus: AmityLoadingStatus = .notLoading
    @Published public var productLoadingStatus: AmityLoadingStatus = .notLoading
    @Published public var isProductMentionEnabled: Bool = false
    @Published public var taggedProductIds: Set<String> = []

    public var onClose: () -> Void = {}
    public var onUserSelected: (AmityMentionUserModel) -> Void = { _ in }
    public var onProductSelected: (AmityProduct) -> Void = { _ in }

    public init() {
        setupSearchObserver()
    }

    private func setupSearchObserver() {
        // Only product search is handled in this view model,
        // user search is handled by MentionManger.MentionListProvider and user list is provided by MentionManagerDelegate.
        searchCancellable = $searchKeyword
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] keyword in
                guard let self else { return }
                self.searchProducts(keyword)
            }
    }

    public func loadMoreUsers() {
        guard let userCollection, userCollection.hasNext else { return }
        userCollection.nextPage()
    }

    // MARK: - Product Search
    private func searchProducts(_ keyword: String) {
        productCancellables.removeAll()

        let queryOptions = AmityProductQueryOptions(keyword: keyword, isActive: true, isDeleted: false)
        productCollection = productManager.searchProducts(queryOptions)

        productCollection?.$snapshots
            .sink { [weak self] products in
                self?.products = products
            }
            .store(in: &productCancellables)

        productCollection?.$loadingStatus
            .sink { [weak self] status in
                self?.productLoadingStatus = status
            }
            .store(in: &productCancellables)
    }

    public func loadMoreProducts() {
        guard let productCollection, productCollection.hasNext else { return }
        productCollection.nextPage()
    }
}

// MARK: - View
public struct TextEditorSuggestionView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @ObservedObject var viewModel: TextEditorSuggestionViewModel

    public init(viewModel: TextEditorSuggestionViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header with tabs and close button
            headerView
                .isHidden(!viewModel.isProductMentionEnabled)
            
            Divider()
                .background(Color(viewConfig.theme.baseColorShade4))
            
            // Content based on selected tab
            ScrollView {
                LazyVStack(spacing: 0) {
                    switch viewModel.selectedTab {
                    case .user:
                        userListView
                    case .product:
                        productListView
                    }
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        .overlay(
            Button(action: viewModel.onClose) {
                Image(AmityIcon.grayCloseIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 22, height: 22)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    .padding(4)
                    .background(Color(viewConfig.theme.backgroundColor))
                    .clipShape(Circle())
                    .shadow(color: Color(red: 0.38, green: 0.38, blue: 0.44).opacity(0.16), radius: 8, x: 0, y: 8)
                    .overlay(Circle().stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1))
            }
            .offset(x: 4, y: -4), alignment: .topTrailing)
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack(spacing: 0) {
            // Tabs
            HStack(spacing: 0) {
                // User tab
                tabButton(
                    icon: AmityIcon.Chat.membersCount.imageResource,
                    isSelected: viewModel.selectedTab == .user,
                    action: { viewModel.selectedTab = .user }
                )

                // Product tab
                tabButton(
                    icon: AmityIcon.LiveStream.emptyProductTaggingIcon.imageResource,
                    isSelected: viewModel.selectedTab == .product,
                    action: { viewModel.selectedTab = .product }
                )
            }
        }
    }

    private func tabButton(icon: ImageResource, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        }) {
            VStack(spacing: 16) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 16, height: 12)
                    .foregroundColor(Color(isSelected ? viewConfig.theme.baseColor : viewConfig.theme.baseColorShade2))
                    .padding(.top, 16)

                Rectangle()
                    .fill(Color(isSelected ? viewConfig.theme.primaryColor : .clear))
                    .frame(height: 2)
            }
        }
    }

    // MARK: - User List View
    @ViewBuilder
    private var userListView: some View {
        if viewModel.userLoadingStatus == .loading && viewModel.users.isEmpty {
            // Loading state
            ForEach(0..<5, id: \.self) { _ in
                UserSuggestionSkeletonRow()
            }
        } else if viewModel.users.isEmpty {
            // No results state
            SuggestionNoResultView(text: "No results found")
                .padding(.top, 12)
        } else {
            // Results state
            ForEach(Array(viewModel.users.enumerated()), id: \.element.userId) { index, user in
                UserSuggestionRow(user: user)
                    .onTapGesture {
                        viewModel.onUserSelected(user)
                    }
                    .onAppear {
                        if index == viewModel.users.count - 1 {
                            viewModel.loadMoreUsers()
                        }
                    }
            }
        }
    }

    // MARK: - Product List View
    @ViewBuilder
    private var productListView: some View {
        if viewModel.searchKeyword.count < 2 {
            // Empty state - if the keyword is < 2
            SuggestionEmptyStateView(text: "Start typing to search for products")
                .padding(.top, 12)
        } else if viewModel.productLoadingStatus == .loading && viewModel.products.isEmpty {
            // Loading state
            ForEach(0..<5, id: \.self) { _ in
                ProductSuggestionSkeletonRow()
            }
        } else if viewModel.products.isEmpty {
            // No results state
            SuggestionNoResultView(text: "No results found")
                .padding(.top, 12)
        } else {
            // Results state
            ForEach(Array(viewModel.products.enumerated()), id: \.element.productId) { index, product in
                let isAlreadyTagged = viewModel.taggedProductIds.contains(product.productId)
                ProductSuggestionRow(product: product, isAlreadyTagged: isAlreadyTagged)
                    .onTapGesture {
                        if !isAlreadyTagged {
                            viewModel.onProductSelected(product)
                        }
                    }
                    .onAppear {
                        if index == viewModel.products.count - 1 {
                            viewModel.loadMoreProducts()
                        }
                    }
            }
        }
    }
}

// MARK: - User Suggestion Row
struct UserSuggestionRow: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController

    let user: AmityMentionUserModel

    var body: some View {
        HStack(spacing: 12) {
            AmityUserProfileImageView(displayName: user.displayName,
                                      avatarURL: URL(string: user.avatarURL))
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            Text(user.displayName)
                .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(1)

            Spacer()
        }
        .padding(.all, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Product Suggestion Row
struct ProductSuggestionRow: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController

    let product: AmityProduct
    var isAlreadyTagged: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(
                placeholderView: {
                    ZStack {
                        Color(viewConfig.theme.baseColorShade4)
                        Image(AmityIcon.LiveStream.productTagImagePlaceholderIcon.imageResource)
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                            .frame(width: 20, height: 20)
                    }
                },
                url: URL(string: product.thumbnailUrl ?? ""),
                contentMode: .fill
            )
            .frame(width: 40, height: 40)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 0) {
                Text(product.productName)
                    .applyTextStyle(isAlreadyTagged ? .captionBold(Color(viewConfig.theme.baseColorShade4)) : .bodyBold(Color(viewConfig.theme.baseColor)))
                    .lineLimit(1)

                if isAlreadyTagged {
                    Text("Already tagged")
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                        .lineLimit(1)
                        .padding(.top, 4)
                }
            }

            Spacer()
        }
        .padding(.all, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - User Suggestion Skeleton Row
struct UserSuggestionSkeletonRow: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 32, height: 32)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 150, height: 14)

            Spacer()
        }
        .padding(.all, 12)
    }
}

// MARK: - Product Suggestion Skeleton Row
struct ProductSuggestionSkeletonRow: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 40, height: 40)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 180, height: 14)

            Spacer()
        }
        .padding(.all, 16)
    }
}

// MARK: - Empty State View
struct SuggestionEmptyStateView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController

    let text: String

    var body: some View {
        VStack(spacing: 12) {
            Image(AmityIcon.defaultSearchIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 28)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))

            Text(text)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade3)))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }
}

// MARK: - No Result View
struct SuggestionNoResultView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController

    let text: String

    var body: some View {
        VStack(spacing: 12) {
            Image(AmityIcon.noSearchableIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 28)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))

            Text(text)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade3)))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }
}
