//
//  AmityJoinRequestContentComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 27/5/25.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityJoinRequestContentComponent: AmityComponentView {
    public var pageId: PageId?
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @EnvironmentObject var viewConfig: AmityViewConfigController

    public var id: ComponentId {
        return .joinRequestContent
    }

    @StateObject var viewModel: AmityJoinRequestsViewModel
    
    public init(community: AmityCommunity, pageId: PageId? = nil, onChange: ((Int) -> Void)? = nil) {
        self.pageId = pageId
        self._viewModel = StateObject(wrappedValue: AmityJoinRequestsViewModel(community: community, onChange: onChange))
        
        UITableView.appearance().separatorStyle = .none
    }
    
    public var body: some View {
        VStack {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 60)
                .overlay(
                    Text(AmityLocalizedStringSet.Social.userJoinRequestDeclineAlertBannerMessage.localizedString)
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                        .padding([.leading, .trailing], 16)
                )
            
            if viewModel.joinRequests.isEmpty {
                getEmptyView()
            } else {
                getContentView()
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
    }
    
    @ViewBuilder
    func getEmptyView() -> some View {
        VStack(spacing: 8) {
            Spacer()
            
            Image(AmityIcon.emptyPendingPostIcon.getImageResource())
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
            
            Text(AmityLocalizedStringSet.Social.communityJoinRequestEmptyStateTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
            
            Spacer()
        }
    }
    
    @ViewBuilder
    func getContentView() -> some View {
        if viewModel.loadingStatus == .loading {
            List {
                ForEach(0..<5, id: \.self) { index in
                    PostContentSkeletonView()
                        .listRowInsets(EdgeInsets())
                        .modifier(HiddenListSeparator())
                }
            }
            .listStyle(.plain)
            .environmentObject(viewConfig)
        } else {
            if #available(iOS 15.0, *) {
                getJoinRequestsListView()
                    .refreshable {
                        viewModel.getPendingJoinRequest()
                    }
            } else {
                getJoinRequestsListView()
            }
        }
    }
    
    @ViewBuilder
    func getJoinRequestsListView() -> some View {
        List {
            ForEach(Array(viewModel.joinRequests.enumerated()), id: \.element.joinRequestId) { index, joinRequest in
                VStack(spacing: 16) {
                    getUserCell(joinRequest)
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 8)
                }
                .listRowInsets(EdgeInsets())
                .modifier(HiddenListSeparator())
                .onAppear {
                    if index == viewModel.joinRequests.count - 1 {
                        viewModel.loadMore()
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    private func getUserCell(_ joinRequest: AmityJoinRequest) -> some View {
        HStack {
            let displayName = joinRequest.user?.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString
            let avatarURL = joinRequest.user?.getAvatarInfo()?.fileURL ?? ""
            let isBrandUser = joinRequest.user?.isBrand ?? false
            AmityUserProfileImageView(displayName: displayName, avatarURL: URL(string: avatarURL))
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            
            Text(displayName)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
            
            Image(AmityIcon.brandBadge.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .padding(.leading, -4)
                .opacity(isBrandUser ? 1 : 0)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            goToUserProfilePage(joinRequest.user?.userId ?? "")
        }
        
        requestActionView(joinRequest)
            .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func requestActionView(_ joinRequest: AmityJoinRequest) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(viewConfig.theme.primaryColor))
                .overlay (
                    Text(AmityLocalizedStringSet.Social.userJoinRequestAcceptLabel.localizedString)
                        .applyTextStyle(.bodyBold(.white))
                )
                .cornerRadius(8)
                .onTapGesture {
                    Task { @MainActor in
                        do {
                            try await viewModel.accept(request: joinRequest)
                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.userJoinAcceptedToastSuccessMessage.localizedString)
                        } catch {
                            if error.isAmityErrorCode(.unknown) {
                                Toast.showToast(style: .warning, message: "This join request is no longer available.")
                            } else {
                                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.userJoinAcceptedToastErrorMessage.localizedString)
                            }
                        }
                    }
                }
            
            Rectangle()
                .fill(.clear)
                .overlay (
                    Text(AmityLocalizedStringSet.Social.userJoinRequestDeclineLabel.localizedString)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(viewConfig.theme.baseColorShade3), lineWidth: 1)
                )
                .onTapGesture {
                    Task { @MainActor in
                        do {
                            try await viewModel.reject(request: joinRequest)
                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.userJoinDeclinedToastSuccessMessage.localizedString)
                        } catch let error {
                            if error.isAmityErrorCode(.unknown) {
                                Toast.showToast(style: .warning, message: "This join request is no longer available.")
                            } else {
                                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.userJoinDeclinedToastErrorMessage.localizedString)
                            }
                        }
                    }
                }
        }
        .frame(height: 40)
    }
    
    private func goToUserProfilePage(_ userId: String) {
        let context = AmityJoinRequestContentComponentBehavior.Context(component: self, userId: userId)
        AmityUIKitManagerInternal.shared.behavior.joinRequestContentComponentBehavior.goTouserProfilePage(context: context)
    }

}

class AmityJoinRequestsViewModel: ObservableObject {
    
    @Published var joinRequests: [AmityJoinRequest] = []
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
    
    private var communityManager = CommunityManager()
    private var joinRequestCollection: AmityCollection<AmityJoinRequest>?
    private var cancellables = Set<AnyCancellable>()
    
    let community: AmityCommunity
    let onChange: ((Int) -> Void)?
    var token: AmityNotificationToken?
    
    init(community: AmityCommunity, onChange: ((Int) -> Void)?) {
        self.community = community
        self.onChange = onChange
        getPendingJoinRequest()
    }
    
    func getPendingJoinRequest() {
        token?.invalidate()
        token = nil
        
        joinRequestCollection = communityManager.getPendingJoinRequests(community: community)
        token = joinRequestCollection?.observe({ [weak self] liveCollection, _, error in
            guard let self else { return }
            
            let snapshots = liveCollection.snapshots
            self.joinRequests = snapshots
            self.onChange?(snapshots.count)
        })
        
        joinRequestCollection?.$loadingStatus
            .assign(to: &$loadingStatus)
    }
    
    func loadMore() {
        if let joinRequestCollection, joinRequestCollection.hasNext {
            joinRequestCollection.nextPage()
        }
    }
    
    @MainActor
    func accept(request: AmityJoinRequest) async throws {
        try await request.approve()
    }
    
    @MainActor
    func reject(request: AmityJoinRequest) async throws {
        try await request.reject()
    }
}
