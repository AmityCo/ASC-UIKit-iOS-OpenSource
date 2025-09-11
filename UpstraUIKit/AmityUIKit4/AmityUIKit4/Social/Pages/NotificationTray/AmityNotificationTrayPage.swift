//
//  AmityNotificationTrayPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 1/4/25.
//

import SwiftUI

public struct AmityNotificationTrayPage: AmityPageView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel = AmityNotificationTrayPageViewModel()
    @StateObject private var invitaionSectionViewModel = AmityInvitationSectionViewModel()
    
    @State private var didMarkTrayAsSeen = false
    
    public var id: PageId {
        return .notificationTrayPage
    }
    
    public init() {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .notificationTrayPage))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            AmityNavigationBar(title: AmityLocalizedStringSet.Social.notificationTrayTitle.localizedString, showBackButton: true)
            
            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        
                        AmityInvitationSection(viewModel: invitaionSectionViewModel)
                            .visibleWhen(invitaionSectionViewModel.loadingStatus != .loading && !viewModel.isLoading && !invitaionSectionViewModel.invitations.isEmpty)
                        
                        ForEach(viewModel.sections) { section in
                            NotificationTraySectionTitle(title: section.title)
                            
                            ForEach(section.notifications) { item in
                                NotificationTrayItemView(item: item)
                                    .onTapGesture {
                                        handleNotificationTap(item: item)
                                    }
                                    .onAppear {
                                        if let lastItem = viewModel.sections.last?.notifications.last, lastItem.id == item.id {
                                            viewModel.fetchMoreNotifications()
                                        }
                                    }
                            }
                        }
                    }
                }
                .onAppear {
                    guard !didMarkTrayAsSeen else { return }
                    
                    viewModel.markTraySeen()
                    
                    didMarkTrayAsSeen = true
                }
                
                emptyNotificationState
                    .padding()
                    .visibleWhen(!viewModel.isLoading && viewModel.sections.isEmpty && invitaionSectionViewModel.invitations.isEmpty)
                
                skeletonState
                    .padding()
                    .visibleWhen(viewModel.isLoading)
            }
            .background(Color(viewConfig.theme.backgroundColor))
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    func handleNotificationTap(item: NotificationItem) {
        // Mark this item as seen
        if !item.isSeen {
            viewModel.markTrayItemSeen(item: item)
        }
        
        let idInfo = item.info
        
        switch item.actionType {
        case .post, .poll:
            if item.targetType == .community {
                // Notification: Created a post | Started a poll in community
                AmityUIKit4Manager.behaviour.notificationTrayPageBehavior.goToCommunityProfilePage(context: AmityNotificationTrayPageBehavior.Context(page: self, postId: nil, commentId: nil, parentCommentId: nil, communityId: idInfo.communityId, userId: nil))
            } else {
                // Notification: Created a post | Started a poll in other feed
                AmityUIKit4Manager.behaviour.notificationTrayPageBehavior.goToPostDetailPage(context: AmityNotificationTrayPageBehavior.Context(page: self, postId: idInfo.postId, commentId: nil, parentCommentId: nil, communityId: nil, userId: nil))
            }
        case .comment, .reply, .reaction, .mention:
            AmityUIKit4Manager.behaviour.notificationTrayPageBehavior.goToPostDetailPage(context: AmityNotificationTrayPageBehavior.Context(page: self, postId: idInfo.postId, commentId: idInfo.commentId, parentCommentId: idInfo.parentId, communityId: nil, userId: nil))
        case .joinRequest:
            AmityUIKit4Manager.behaviour.notificationTrayPageBehavior.goToCommunityProfilePage(context: AmityNotificationTrayPageBehavior.Context(page: self, postId: nil, commentId: nil, parentCommentId: nil, communityId: idInfo.communityId, userId: nil))
        case .follow:
            AmityUIKit4Manager.behaviour.notificationTrayPageBehavior.goToUserProfilePage(context: AmityNotificationTrayPageBehavior.Context(page: self, postId: nil, commentId: nil, parentCommentId: nil, communityId: nil, userId: idInfo.userId))
        }
    }
    
    @ViewBuilder
    var emptyNotificationState: some View {
        VStack {
            Image(AmityIcon.emptyNotificationList.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
            
            Text(AmityLocalizedStringSet.Social.notificationTrayEmptyStateTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
        }
    }
    
    @ViewBuilder
    var noInternetConnectionState: some View {
        VStack {
            Image(AmityIcon.noInternetIcon.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
            
            Text(AmityLocalizedStringSet.General.noInternetConnection.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
        }
    }
    
    
    @ViewBuilder
    var skeletonState: some View {
        VStack(alignment: .leading) {
            skeletonSection
            skeletonSection
            
            Spacer()
        }
    }
    
    
    @ViewBuilder
    var skeletonSection: some View  {
        VStack(alignment: .leading, spacing: 0) {
            
            SkeletonRectangle(height: 10, width: 130, cornerRadius: 5)
                .padding(.vertical, 8)
            
            skeletonRow
            skeletonRow
            skeletonRow
        }
    }
    
    @ViewBuilder
    var skeletonRow: some View {
        HStack {
            SkeletonRectangle(height: 32, width: 32, cornerRadius: 16)
            
            VStack(alignment: .leading) {
                SkeletonRectangle(height: 10, width: 230, cornerRadius: 10)
                SkeletonRectangle(height: 10, width: 132, cornerRadius: 10)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
}
