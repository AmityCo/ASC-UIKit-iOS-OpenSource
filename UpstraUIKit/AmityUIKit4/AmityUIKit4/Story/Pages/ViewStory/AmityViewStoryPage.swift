//
//  AmityViewStoryPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/29/23.
//

import SwiftUI
import AVKit
import AmitySDK
import Combine

public enum AmityViewStoryPageType {
      case communityFeed(String)
      // User can start viewing any specific story target in Global Feed.
      // It will be the communityId of story target that user clicked on AmityStoryTabComponent
      // in our UI flow.
      case globalFeed(String)
}

public struct AmityViewStoryPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .storyPage
    }

    @StateObject var viewModel: AmityViewStoryPageViewModel
    @State private var hasStoryManagePermission: Bool = false
    @State private var page: Page = Page.first()
        
    private let storyPageType: AmityViewStoryPageType
    
    @StateObject private var viewConfig: AmityViewConfigController
    @Environment(\.colorScheme) private var colorScheme
    
    public init(type: AmityViewStoryPageType) {
        self.storyPageType = type
        _viewModel = StateObject(wrappedValue: AmityViewStoryPageViewModel(type: type))
        _viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .storyPage))
    }
    
   
    public var body: some View {
        ZStack {
            Color.clear
                .overlay (
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .isHidden(!viewModel.showActivityIndicator)
                )
                .overlay(
                    closeButton
                        .padding(.top, 40)
                        .isHidden(viewModel.storyTargets.element(at: viewModel.storyTargetIndex)?.itemCount != 0)
                , alignment: .topTrailing)
                .onReceive(viewModel.$storyTargetLoadingStatus) { status in
                    if case .globalFeed(let communityId) = storyPageType {
                        let index = viewModel.storyTargets.firstIndex { $0.targetId == communityId } ?? 0
                        viewModel.storyTargetIndex = index
                        page.update(.new(index: index))
                    }
                    
                    if case .communityFeed(_) = storyPageType {
                        viewModel.storyTargetIndex = 0
                        page.update(.new(index: 0))
                    }
                }
                .zIndex(1)
            
            if viewModel.storyTargetLoadingStatus == .loaded || !viewModel.storyTargets.isEmpty {
                Pager(page: page, data: viewModel.storyTargets, id: \.targetId) { storyTarget in
                    StoryCoreView(self,
                                  storyPageViewModel: viewModel,
                                  storyTarget: storyTarget)
                    .environmentObject(host)
                }
                .contentLoadingPolicy(.lazy(recyclingRatio: 4))
                .interactive(rotation: true)
                .interactive(scale: 0.7)
                .itemSpacing(-60)
                .horizontal()
                .allowsDragging(viewModel.storyTargets.count != 1)
                .pagingPriority(.simultaneous)
                .sensitivity(.custom(0.35))
                .delaysTouches(false)
                .onDraggingBegan({
                    viewModel.debounceUpdateShouldRunTimer(false)
                })
                .onDraggingEnded({
                    viewModel.debounceUpdateShouldRunTimer(true)
                })
                .draggingAnimation(onChange: .custom(animation: .easeInOut(duration: 0.3)), onEnded: .custom(animation: .easeInOut(duration: 0.3)))
                .onPageChanged({ index in
                    viewModel.debounceUpdateStoryTargetIndex(index)
                })
                .onChange(of: viewModel.storyTargetIndex) { index in
                    guard page.index != index else { return }
                    page.update(.new(index: index))
                }
                .onDisappear {
                    viewModel.shouldRunTimer =  false
                }
            }
        }
        .environmentObject(viewConfig)
        .background(Color.black.ignoresSafeArea(edges: .top))
        .ignoresSafeArea(edges: .bottom)
        .statusBarHidden()
        .onChange(of: colorScheme) { value in
            viewConfig.updateTheme()
        }
    }
    
    @ViewBuilder
    private var closeButton: some View {
        Button {
            Log.add(event: .info, "Tapped Closed!!!")
            host.controller?.dismiss(animated: true)
        } label: {
            let icon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .closeButtonElement, key: "close_icon", of: String.self) ?? "")
            Image(icon)
                .frame(width: 24, height: 18)
                .padding(.trailing, 25)
        }
    }
}
