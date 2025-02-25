//
//  AmityReactionList.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 3/13/24.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityReactionList: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    public var id: ComponentId {
        return .reactionList
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityReactionListViewModel
    
    @State private var currentTab: Int = 0
    @State private var tabBarItems: [ReactionTabItem] = []
    @StateObject private var page = Page.withIndex(0)
    
    @Environment(\.presentationMode) var dismissScreen
    
    public init(referenceId: String, referenceType: AmityReactionReferenceType, pageId: PageId? = nil) {
        self.pageId = pageId
        self._viewModel = StateObject(wrappedValue: AmityReactionListViewModel(referenceId: referenceId, referenceType: referenceType))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .reactionList))
        self._tabBarItems = State(wrappedValue: setupTabItems(reactions: [:], reactionCount: 0))
        
        // Resolve reaction info to create tabs
        viewModel.resolveReactionInfo { reactions, totalCount in
            self._tabBarItems = State(wrappedValue: setupTabItems(reactions: reactions, reactionCount: totalCount))
        }
    }
    
    /// Convenience initializer
    init(message: AmityMessage, pageId: PageId? = nil) {
        self.pageId = pageId
        self._viewModel = StateObject(wrappedValue: AmityReactionListViewModel(referenceId: message.messageId, referenceType: .message))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .reactionList))
        self._tabBarItems = State(wrappedValue: setupTabItems(reactions: message.reactions as? [String: Int] ?? [:], reactionCount: message.reactionCount))
    }
    
    /// Convenience initializer
    init(comment: AmityComment, pageId: PageId? = nil) {
        self.pageId = pageId
        self._viewModel = StateObject(wrappedValue: AmityReactionListViewModel(referenceId: comment.commentId, referenceType: .comment))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .reactionList))
        self._tabBarItems = State(wrappedValue: setupTabItems(reactions: comment.reactions as? [String: Int] ?? [:], reactionCount: comment.reactionsCount))
    }
    
    /// Convenience initializer
    public init(post: AmityPost, pageId: PageId? = nil) {
        self.pageId = pageId
        self._viewModel = StateObject(wrappedValue: AmityReactionListViewModel(referenceId: post.postId, referenceType: .post))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .reactionList))
        self._tabBarItems = State(wrappedValue: setupTabItems(reactions: post.reactions as? [String: Int] ?? [:], reactionCount: post.reactionsCount))
    }
    
    public var body: some View {
        VStack {
            BottomSheetDragIndicator()
                .foregroundColor(Color(viewConfig.defaultLightTheme.baseColorShade3))
            
            // Header Tabs
            ReactionListHeader(currentTab: $currentTab, tabBarItems: $tabBarItems)
            
            // Reaction user list swipable pages
            Pager(page: page, data: tabBarItems, id: \.id) { tabItem in
                ReactionListContent(viewModel: ReactionLoader(referenceId: viewModel.referenceId, referenceType: viewModel.referenceType, reactionName: getReactionType(for: tabItem.index)))
            }
            .onPageWillChange({ pageIndex in
                currentTab = pageIndex
            })
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .onChange(of: currentTab, perform: { value in
            if page.index != currentTab {
                page.update(.new(index: value))
            }
        })
        .onChange(of: viewModel.reactionInfo, perform: { value in
            updateReactionsCount(reactions: value)
        })
        .updateTheme(with: viewConfig)
    }
    
    func getReactionType(for tabIndex: Int) -> String? {
        let tab = tabBarItems[tabIndex]
        return tab.isAllReactionTab() ? nil : tab.name
    }
    
    func setupTabItems(reactions: [String: Int], reactionCount: Int) -> [ReactionTabItem] {
        // Setup reactions tab
        var tabIndex = -1
        var tabs = [ReactionTabItem]()
        
        let filteredReactions = reactions.filter { $0.value > 0 }
        if filteredReactions.count > 1 {
            tabIndex += 1
            let allTabs = ReactionTabItem(index: tabIndex, name: AmityLocalizedStringSet.Reaction.allTab.localizedString, image: nil, count: reactionCount)
            tabs.append(allTabs)
        }
        
        // In descending order of reaction count.
        let sortedReactions = filteredReactions.sorted {
            // If reaction count is same, sort based on key name
            if $0.value == $1.value {
                return $0.key < $1.key
            }
            return $0.value > $1.value
        }
        
        sortedReactions.forEach { item in
            let reactionConfig = MessageReactionConfiguration.shared.getReaction(withName: item.key)
            tabIndex += 1
            let reactionTab = ReactionTabItem(index: tabIndex, name: item.key, image: reactionConfig.image, count: item.value)
            tabs.append(reactionTab)
        }
        
        return tabs
    }
    
    // Updates reactions count in tabs with respect to changes
    func updateReactionsCount(reactions: [String: Int]) {
        var availableReactions = Set(reactions.keys)
        
        let filteredReactions = reactions.filter { $0.value > 0 }
        
        // All tab bar items
        for item in tabBarItems {
            // Skip All tab update
            if item.isAllReactionTab() {
                let updatedItem = ReactionTabItem(index: item.index, name: item.name, image: item.image, count: viewModel.reactionTotalCount)
                tabBarItems[item.index] = updatedItem
            } else {
                // Update other tabs at their respective index.
                let updatedCount = reactions[item.name] ?? 0
                let updatedItem = ReactionTabItem(index: item.index, name: item.name, image: item.image, count: updatedCount)
                tabBarItems[item.index] = updatedItem
            }
            
            // Remove handled reactions
            availableReactions.remove(item.name)
        }
        let isAllTabPresent = tabBarItems[0].isAllReactionTab()
        let isMoreThanOneReaction = filteredReactions.count > 1
        
        if !isAllTabPresent && isMoreThanOneReaction {
            tabBarItems = setupTabItems(reactions: reactions, reactionCount: viewModel.reactionTotalCount)
        } else {
            // If any new type of reactions are added, show it in tabs
            var tabIndex = tabBarItems.count - 1
            for item in availableReactions {
                let reactionConfig = MessageReactionConfiguration.shared.getReaction(withName: item)
                let reactionCount = reactions[item] ?? 0
                if reactionCount > 0 {
                    tabIndex += 1
                    let tabItem = ReactionTabItem(index: tabIndex, name: item, image: reactionConfig.image, count: reactionCount)
                    tabBarItems.append(tabItem)
                }
            }
        }
    }
}
