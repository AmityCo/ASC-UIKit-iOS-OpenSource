//
//  CollapseableScrollView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 6/11/25.
//

import SwiftUI

private struct StickyViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct CollapseableScrollView<ExpandedHeader: View, CollapsedHeader: View, StickyHeader: View, Content: View>: View {
    
    private var collapseThreshold: CGFloat {
        return expandedSectionHeight - collapsedSectionHeight - 2
    }
    
    @State private var scrollOffset: CGFloat = 0
    @State private var stickyViewOffset: CGFloat = 0
    @State private var isHeaderCollapsed: Bool = false
    @State private var isStickyViewPinned: Bool = false
    @State private var startedScrollingToTop: Bool = false
    
    /// The height of the sticky section
    @State private var stickySectionHeight: CGFloat = 0

    let expanded: () -> ExpandedHeader
    let collapsed: () -> CollapsedHeader
    let stickyheader: () -> StickyHeader
    let content: () -> Content
    let onScrollOffsetChange: ((_ offset: CGFloat) -> Void)?
    let onHeaderStateChange: ((_ isCollapsed: Bool) -> Void)?
    
    /// The height of the section which is expanded or collapsed. If your header has a banner image which is to be expanded or collapsed, then this is the height of the banner image in expanded state.
    let expandedSectionHeight: CGFloat
    
    /// The height of the section when collapsed.
    let collapsedSectionHeight: CGFloat
    
    // Note:
    // Due to how preferenceKey is being setup & propagated inside this scrollview,
    // if there are multiple views in sticky header, do not wrap them in VStack
    init(@ViewBuilder expanded: @escaping () -> ExpandedHeader,
         @ViewBuilder collapsed: @escaping () -> CollapsedHeader,
         @ViewBuilder stickyHeader: @escaping () -> StickyHeader,
         @ViewBuilder content: @escaping () -> Content,
         onScrollOffsetChange: ((CGFloat) -> Void)? = nil,
         onHeaderStateChange: ((Bool) -> Void)? = nil,
         expandedSectionHeight: CGFloat = 188,
         collapsedSectionHeight: CGFloat = 105,
    ) {
        self.expanded = expanded
        self.collapsed = collapsed
        self.stickyheader = stickyHeader
        self.content = content
        self.onScrollOffsetChange = onScrollOffsetChange
        self.onHeaderStateChange = onHeaderStateChange
        self.expandedSectionHeight = expandedSectionHeight
        self.collapsedSectionHeight = collapsedSectionHeight
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            
            expanded()
                .opacity(startedScrollingToTop ? 0 : 1)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    expanded()
                        .opacity(!startedScrollingToTop ? 0.01 : 1)
                    
                    VStack(spacing: 0) {
                        stickyheader()
                            .background(
                                // Track sticky view position relative to scroll container
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: StickyViewOffsetKey.self,
                                        value: geo.frame(in: .named("scroll")).minY
                                    )
                                }
                            )
                    }
                    .opacity(isStickyViewPinned ? 0 : 1)
                    .onPreferenceChange(StickyViewOffsetKey.self) { offset in
                        stickyViewOffset = offset
                        updateStickyViewState(offset: offset)
                    }
                    .readSize { size in
                        stickySectionHeight = size.height
                    }
                    
                    content()
                }
                .background(
                    // Track overall scroll offset
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .named("scroll")).minY
                        )
                    }
                )
                .onPreferenceChange(ScrollOffsetKey.self) { offset in
                    scrollOffset = offset
                    
                    if startedScrollingToTop != (offset < 0) {
                        startedScrollingToTop.toggle()
                    }
                    
                    updateHeaderState(offset: offset)
                    
                    onScrollOffsetChange?(offset)
                }
            }
            .coordinateSpace(name: "scroll")
            
            VStack(spacing: 0) {
                // CollapsedView
                if isHeaderCollapsed {
                    collapsed()
                        .frame(height: collapsedSectionHeight)
                        .transition(.opacity)
                    
                }
                
                if isStickyViewPinned {
                    stickyheader()
                        .background(Color.yellow)
                }
            }
        }
        .edgesIgnoringSafeArea(.top)
    }
    
    // Updates sticky view pinned state
    // Sticky view should pin when it reaches the bottom of collapsed header
    private func updateStickyViewState(offset: CGFloat) {
        let shouldPin = isHeaderCollapsed && offset <= collapsedSectionHeight + stickySectionHeight
        
        if shouldPin != isStickyViewPinned {
            isStickyViewPinned = shouldPin
        }
    }
    
    // Updates header collapsed state based on scroll offset
    private func updateHeaderState(offset: CGFloat) {
        let shouldCollapse = offset < -collapseThreshold
        
        if shouldCollapse != isHeaderCollapsed {
            withAnimation(.easeInOut) {
                isHeaderCollapsed = shouldCollapse
            }
            
            onHeaderStateChange?(shouldCollapse)
        }
    }
}

#if DEBUG
#Preview {
    CollapseableScrollView {
        VStack(spacing: 0) {
            AsyncImage(placeholder: AmityIcon.eventImagePlaceholder.imageResource, url: URL(string: ""), contentMode: .fill)
                .frame(height: 188)
            
            Rectangle()
                .fill(Color.gray)
                .frame(height: 120)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            Rectangle()
                .fill(Color.blue)
                .frame(height: 120)
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
    } collapsed: {
        VStack(spacing: 0) {
            ZStack {
                AsyncImage(placeholder: AmityIcon.eventImagePlaceholder.imageResource, url: URL(string: ""), contentMode: .fill)
                    .frame(height: 105)
                
                VisualEffectView(effect: UIBlurEffect(style: .regular), alpha: 1)
            }
            .frame(height: 105)
        }
    } stickyHeader: {
        HStack {
            Text("Tab 1")
                .frame(maxWidth: .infinity)
            Text("Tab 2")
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.yellow)
    } content: {
        VStack(spacing: 0) {
            ForEach(0..<50) { index in
                Rectangle()
                    .fill(Color.green)
                    .frame(height: 120)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
        }
    }
}
#endif
