//
//  AmityInvitationSection.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/16/25.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityInvitationSection: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    public var pageId: PageId?
    
    @ObservedObject private var viewModel: AmityInvitationSectionViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    
    public var id: ComponentId {
        .invitationSection
    }
    
    public init(pageId: PageId? = nil, viewModel: AmityInvitationSectionViewModel) {
        self.pageId = pageId
        self.viewModel = viewModel
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .notificationTrayPage, componentId: .invitationSection))
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NotificationTraySectionTitle(title: "Requests")
            
            ForEach(Array(viewModel.invitations), id: \.invitationId) { invitation in
                NotificationTrayInvitationItemView(invitation: invitation)
                    .background(Color(invitation.isSeen() ? viewConfig.theme.backgroundColor : viewConfig.theme.primaryColor.blend(.shade3)))
                    .onTapGesture {
                        invitation.markAsSeen()
                        goToCommunityProfilePage(communityId: invitation.targetId)
                    }
            }
        }
    }
    
    private func goToCommunityProfilePage(communityId: String) {
        let page = AmityCommunityProfilePage(communityId: communityId)
        let vc = AmitySwiftUIHostingController(rootView: page)
        host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}

public class AmityInvitationSectionViewModel: ObservableObject {
    @Published var invitations: [AmityInvitation] = []
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
    private let invitationManager = InvitationManager()
    private var invitationCancellable: AnyCancellable?
    private var invitationCollection: AmityCollection<AmityInvitation>?
    private var loadingStatusCancellable: AnyCancellable?
    
    init() {
        getMyInvitations()
    }
    
    private func getMyInvitations() {
        invitationCollection = invitationManager.getMyCommunityInvitations()
        invitationCancellable = invitationCollection?.$snapshots
            .sink(receiveValue: { [weak self] invitations in
                self?.invitations = invitations.prefix(3).map { $0 }
            })
        
        loadingStatusCancellable = invitationCollection?.$loadingStatus
            .sink(receiveValue: { [weak self] status in
                self?.loadingStatus = status
            })
    }
}
