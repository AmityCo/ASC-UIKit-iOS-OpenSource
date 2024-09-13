//
//  AmityCommunityAddCategoryPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/8/24.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityCommunityAddCategoryPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    
    public var id: PageId {
        .communityAddCategoryPage
    }
    
    @StateObject private var viewModel: AmityCommunityAddCategoryPageViewModel = AmityCommunityAddCategoryPageViewModel()
    @State private var selectedCategories: [AmityCommunityCategoryModel] = []
    private let onAddedAction: ([AmityCommunityCategoryModel]) -> Void
    
    public init(categories: [AmityCommunityCategoryModel], onAddedAction: @escaping ([AmityCommunityCategoryModel]) -> Void) {
        self.onAddedAction = onAddedAction
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communityAddCategoryPage))
        self._selectedCategories = State(initialValue: categories)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            navigationBarView
                .padding(EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 16))
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
            
            if !selectedCategories.isEmpty {
                CategoryGridView(categories: $selectedCategories)
                    .environmentObject(viewConfig)
                    .padding(.all, 16)
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
            }
            
            ScrollView {
                Color.clear.frame(height: 16)
                
                LazyVStack(spacing: 16, content: {
                    ForEach(Array(viewModel.categories.enumerated()), id: \.element.categoryId) { index, category in
                        let isSelected = isSelectedCategory(category)
                        
                        getCategoryView(category, isSelected: isSelected)
                            .onTapGesture {
                                if isSelected {
                                    selectedCategories.remove(at: selectedCategories.firstIndex(of: category) ?? 0)
                                } else {
                                    guard selectedCategories.count < 10 else { return }
                                    selectedCategories.append(category)
                                }
                            }
                            .onAppear {
                                if index == viewModel.categories.count - 1 {
                                    viewModel.loadMoreCategories()
                                }
                            }
                    }
                })
            }
            .padding(.leading, 16)
            
            addCategoryButtonView
                .padding(.bottom, 10)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
    }
    
    private var navigationBarView: some View {
        HStack(spacing: 0) {
            Image(AmityIcon.closeIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .frame(width: 24, height: 24)
                .onTapGesture {
                    host.controller?.dismiss(animated: true)
                }
            
            Spacer()
            
            Text("Select category")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(viewConfig.theme.baseColor))
            
            Spacer()
            
            Text("\(selectedCategories.count)/10")
                .font(.system(size: 15))
                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
        }
    }
    
    private var addCategoryButtonView: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
            
            Rectangle()
                .fill(.blue)
                .frame(height: 40)
                .cornerRadius(4)
                .overlay (
                    ZStack {
                        Text("Add Category")
                            .font(.system(size: 15.0, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4).opacity(0.5))
                            .isHidden(!selectedCategories.isEmpty, remove: true)
                    }
                )
                .onTapGesture {
                    guard !selectedCategories.isEmpty else { return }
                    
                    onAddedAction(selectedCategories)
                    host.controller?.dismiss(animated: true)
                }
                .padding([.leading, .trailing], 16)
        }
    }
    

    private func getCategoryView(_ category: AmityCommunityCategoryModel, isSelected: Bool) -> some View {
        ZStack {
            HStack(spacing: 12) {
                AsyncImage(placeholder: AmityIcon.defaultCommunity.getImageResource(), url: URL(string: category.avatarURL))
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                Text(category.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(lineWidth: 2.0)
                        .fill(.gray)
                        .frame(width: 16, height: 16)
                        .isHidden(isSelected)
                    
                    Image(AmityIcon.checkboxIcon.getImageResource())
                        .frame(width: 22, height: 22)
                        .isHidden(!isSelected)
                        .offset(x: 3)
                }
                .padding(.trailing, 18)
            }
            
            Color.clear // Invisible overlay for tap event
                .contentShape(Rectangle())
        }
    }
    
    
    private func isSelectedCategory(_ category: AmityCommunityCategoryModel) -> Bool {
        return selectedCategories.contains { $0.categoryId == category.categoryId }
    }
    
    
    
}

class AmityCommunityAddCategoryPageViewModel: ObservableObject {
    
    private let collection: AmityCollection<AmityCommunityCategory>
    private let communityManager: CommunityManager = CommunityManager()
    private var cancellable: AnyCancellable?
    
    @Published var categories: [AmityCommunityCategoryModel] = []
    
    init() {
        self.collection = communityManager.getCategories()
        cancellable = collection.$snapshots
            .sink(receiveValue: { [weak self] items in
                self?.categories = items.map { AmityCommunityCategoryModel(object: $0) }
            })
    }
    
    func loadMoreCategories() {
        guard collection.hasNext else { return }
        collection.nextPage()
    }
}
