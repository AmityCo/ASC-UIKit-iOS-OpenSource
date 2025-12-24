//
//  AmityEventDetailPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 3/11/25.
//

import SwiftUI
import AmitySDK

public struct AmityEventDetailPage: AmityPageView {
    
    public var id: PageId {
        return .eventDetailPage
    }
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject var viewConfig: AmityViewConfigController = .init(pageId: .eventDetailPage)
    
    @StateObject var viewModel: AmityEventDetailPageViewModel
    
    @State private var currentTab: Int = 0
    @State var showMenuBottomSheet = false
    @State private var isHeaderCollapsed = false
    @State var showCreateBottomSheet: Bool = false
    @State var showPollSelectionView: Bool = false
    
    @StateObject var alertHandler = EventDetailPageAlert()
    
    var context: AmityEventDetailPage.Context?
    
    public init(event: AmityEvent) {
        self._viewModel = StateObject(wrappedValue: AmityEventDetailPageViewModel(event: event))
    }
    
    public init(eventId: String) {
        self._viewModel = StateObject(wrappedValue: AmityEventDetailPageViewModel(eventId: eventId))
    }
    
    init(event: AmityEvent, context: Context) {
        self._viewModel = StateObject(wrappedValue: AmityEventDetailPageViewModel(event: event))
        self.context = context
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            CollapseableScrollView(expanded: {
                expandedHeaderView
            }, collapsed: {
                collapsedHeaderView
            }, stickyHeader: {
                
                if viewModel.canSetupLiveStream() {
                    setupLivestreamButton
                }
                
                EventDetailTabBarView(currentTab: $currentTab)
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
            }, content: {
                AmityEventInfoComponent(viewModel: viewModel)
                    .isHidden(currentTab != 0)
                
                AmityEventDiscussionFeedComponent(viewModel: viewModel)
                    .isHidden(currentTab != 1)
            }, onHeaderStateChange: { isCollapsed in
                self.isHeaderCollapsed = isCollapsed
            })
            .visibleWhen(viewModel.event != nil)
            
            VStack {
                topNavigationView
                    .padding(.top, 44)
                
                Spacer()
            }
            .bottomSheet(isShowing: $showMenuBottomSheet, height: .contentSize) {
                menuOptionSheet
            }
            
            let isVisitorUser = AmityUIKitManagerInternal.shared.isGuestUser
            let hasJoinedCommunity = viewModel.event?.targetCommunity?.isJoined ?? false
            let hasPermissionToCreate = !isVisitorUser && hasJoinedCommunity
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    createPostView
                        .padding(.bottom, 32)
                }
            }
            .isHidden(currentTab != 1 || !hasPermissionToCreate)
            
            PostDetailEmptyStateView(action: {
                if let context, context.isNewEvent {
                    host.controller?.navigationController?.dismiss(animated: true)
                } else {
                    host.controller?.navigationController?.popViewController(animated: true)
                }
            })
            .visibleWhen(viewModel.isEventUnavailable)
            
            loadingState
                .visibleWhen(viewModel.isLoadingEvent && viewModel.event == nil && !viewModel.isEventUnavailable)
        }
        .alert(isPresented: $alertHandler.isPresented, content: {
            if let dismissButton = alertHandler.alertState.dismissButton {
                Alert(title: Text(alertHandler.alertState.title), message: Text(alertHandler.alertState.message), dismissButton: dismissButton)
            } else {
                Alert(title: Text(alertHandler.alertState.title), message: Text(alertHandler.alertState.message), primaryButton: alertHandler.alertState.primaryButton, secondaryButton: alertHandler.alertState.secondaryButton)
            }
        })
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .edgesIgnoringSafeArea(.top)
        .environmentObject(alertHandler)
    }
    
    @ViewBuilder
    var expandedHeaderView: some View {
        if let event = viewModel.event {
            EventDetailHeaderView(viewModel: viewModel, event: event, onAttendeeTap: {
                guard let event = viewModel.event, let isJoined = viewModel.community?.isJoined, isJoined else { return }
                
                AmityUIKit4Manager.behaviour.eventDetailPageBehavior?.goToEventAttendeesPage(context: .init(page: self, event: event))
            }, onUserTap: {
                AmityUIKit4Manager.behaviour.eventDetailPageBehavior?.goToUserProfilePage(context: .init(page: self, event: event))
                
            }, onCommunityTap: {
                AmityUIKit4Manager.behaviour.eventDetailPageBehavior?.goToCommunityProfilePage(context: .init(page: self, event: event))
            })
        } else {
            EmptyView()
        }
    }
    
    var collapsedHeaderView: some View {
        VStack(spacing: 0) {
            // 1. Cover Image
            ZStack {
                AsyncImage(placeholder: AmityIcon.eventImagePlaceholder.imageResource, url: URL(string: viewModel.event?.coverImage?.mediumFileURL ?? ""), contentMode: .fill)
                    .frame(height: 105, alignment: .top)
                    .clipped()
                
                VisualEffectView(effect: UIBlurEffect(style: .regular), alpha: 1)
                    .frame(height: 105)
            }
        }
    }
    
    @ViewBuilder
    var topNavigationView: some View {
        HStack(spacing: 0) {
            
            backButton
            
            // Show event name as sticky header
            Text(viewModel.event?.title ?? "")
                .applyTextStyle(.titleBold(Color(viewConfig.theme.backgroundColor)))
                .lineLimit(1)
                .padding(.horizontal, 12)
                .opacity(isHeaderCollapsed ? 1 : 0)
            
            Spacer()
            
            Image(AmityIcon.threeDotIcon.imageResource)
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(Color(viewConfig.theme.backgroundColor))
                .background(
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColor.withAlphaComponent(0.5)))
                        .clipShape(RoundedCorner())
                        .padding(.all, -4)
                    
                )
                .onTapGesture {
                    showMenuBottomSheet.toggle()
                }
                .opacity(shouldShowEventMenuOption() ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // height: 80 (including padding)
    var setupLivestreamButton: some View {
        // 2. Live stream button
        Button {
            // start live stream
            guard let event = viewModel.event else { return }
            AmityUIKitManagerInternal.shared.behavior.eventDetailPageBehavior?.goToLivestreamPostComposerPage(context: .init(page: self, event: event))
        } label: {
            HStack {
                Image(AmityIcon.externalPlatformIcon.imageResource)
                    .renderingMode(.template)
                    .foregroundColor(.white)
                
                Text(AmityLocalizedStringSet.Social.eventDetailPageSetupLivestream.localizedString)
            }
        }
        .buttonStyle(AmityPrimaryButtonStyle(viewConfig: viewConfig))
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(viewConfig.theme.backgroundColor))
    }
    
    // Create post button
    @ViewBuilder
    var createPostView: some View {
        Button(action: {
            AmityUserAction.perform(host: host) {
                showCreateBottomSheet.toggle()
            }
        }, label: {
            ZStack {
                Rectangle()
                    .fill(Color(viewConfig.theme.primaryColor))
                    .clipShape(RoundedCorner())
                    .frame(width: 64, height: 64)
                    .shadow(radius: 4, y: 2)
                Image(AmityIcon.plusIcon.imageResource)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color(viewConfig.theme.backgroundColor))
            }
        })
        .buttonStyle(BorderlessButtonStyle())
        .padding(.trailing, 16)
        .padding(.bottom, 8)
        .bottomSheet(isShowing: $showCreateBottomSheet, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
            createPostOptionSheet
        }
        .bottomSheet(isShowing: $showPollSelectionView, height: .contentSize, sheetContent: {
            pollTypeSelectionSheet
        })
    }
    
    var backButton: some View {
        Image(AmityIcon.backIcon.imageResource)
            .renderingMode(.template)
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundColor(Color(viewConfig.theme.backgroundColor))
            .background(
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColor.withAlphaComponent(0.5)))
                    .clipShape(RoundedCorner())
                    .padding(.all, -4)
                
            )
            .onTapGesture {
                if let context, context.isNewEvent {
                    host.controller?.navigationController?.dismiss(animated: true)
                    return
                }
                
                host.controller?.navigationController?.popViewController(animated: true)
            }
    }
    
    var loadingState: some View {
        VStack(alignment: .leading, spacing: 8) {
            SkeletonRectangle(height: 188, cornerRadius: 0, isExpanded: true)
                .overlay(
                    HStack {
                        backButton
                        
                        Spacer()
                    }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                SkeletonRectangle(width: 156)
                SkeletonRectangle(width: 280)
                
                
                SkeletonRectangle(height: 8, width: 58)
                    .padding(.top, 24)
                SkeletonRectangle(width: 164)
                
                SkeletonRectangle(height: 8, width: 58)
                    .padding(.top, 14)
                
                SkeletonRectangle(width: 164)
                
                SkeletonRectangle(height: 8, width: 58)
                    .padding(.top, 14)
                
                SkeletonRectangle(width: 164)
            }
            .padding(16)
            
            VStack(spacing: 0) {
                EventDetailTabBarView(currentTab: $currentTab)
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                SkeletonRectangle(width: 140)
                    .padding(.top, 6)
                
                
                SkeletonRectangle(width: 140)
                    .padding(.top, 28)
                
                SkeletonRectangle(width: 244)
                SkeletonRectangle(width: 100)
            }
            .padding(16)
            
            Spacer()
        }
    }
}

extension AmityEventDetailPage {
    
    struct Context {
        var isNewEvent: Bool
        
        init(isNewEvent: Bool) {
            self.isNewEvent = isNewEvent
        }
    }
}
