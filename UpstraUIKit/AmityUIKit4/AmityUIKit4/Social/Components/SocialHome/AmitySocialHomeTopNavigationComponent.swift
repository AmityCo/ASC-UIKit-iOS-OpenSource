//
//  AmitySocialHomeTopNavigationComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/2/24.
//

import SwiftUI
import AmitySDK

public struct AmitySocialHomeTopNavigationComponent: AmityComponentView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    public var pageId: PageId?
    
    public var id: ComponentId {
        .socialHomePageTopNavigationComponent
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var showPostCreationMenu: Bool = false
    private let selectedTab: AmitySocialHomePageTab
    
    private var searchButtonAction: DefaultTapAction?
    private var notificationButtonAction: DefaultTapAction?
    
    @StateObject var viewModel = SocialHomePageNavigationViewModel()
    
    public init(pageId: PageId? = nil,
                selectedTab: AmitySocialHomePageTab = .newsFeed,
                searchButtonAction: DefaultTapAction? = nil,
                notificationButtonAction: DefaultTapAction? = nil
    ) {
        self.pageId = pageId
        self.selectedTab = selectedTab
        self.searchButtonAction = searchButtonAction
        self.notificationButtonAction = notificationButtonAction
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .socialHomePageTopNavigationComponent))
    }
    
    
    public var body: some View {
        HStack(spacing: 10) {
            let headerLabel = viewConfig.getConfig(elementId: .headerLabel, key: "text", of: String.self) ?? ""
            Text(headerLabel)
                .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))
                .padding([.top, .bottom], 15.5)
                .isHidden(viewConfig.isHidden(elementId: .headerLabel), remove: true)
                .accessibilityIdentifier(AccessibilityID.Social.SocialHomePage.headerLabel)
            
            Spacer()
            
            Button(action: {
                notificationButtonAction?()
                
                viewModel.resetNotificationStatus()
            }, label: {
                    VStack {
                        let searchIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .notificationTrayButton, key: "icon", of: String.self) ?? "bellIcon")
                        Image(searchIcon)
                            .frame(size: CGSize(width: 21.0, height: 16.0))
                    }
                    .frame(size: CGSize(width: 32.0, height: 32.0))
                    .background(Color(viewConfig.theme.secondaryColor.blend(.shade4)))
                    .clipShape(Circle())
                    .overlay(
                        NotificationIndicator()
                            .offset(x: 13, y: -12)
                            .visibleWhen(viewModel.hasUnseenNotification || viewModel.hasInvitations)
                    )
                    
            })
            .accessibilityIdentifier(AccessibilityID.Social.SocialHomePage.notificationTrayButton)
            .onAppear {
                viewModel.observeNotificationStatus()
            }

            Button(action: {
                searchButtonAction?()
            }, label: {
                VStack {
                    let searchIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .globalSearchButton, key: "icon", of: String.self) ?? "")
                    Image(searchIcon)
                        .frame(size: CGSize(width: 21.0, height: 16.0))
                }
                .frame(size: CGSize(width: 32.0, height: 32.0))
                .background(Color(viewConfig.theme.secondaryColor.blend(.shade4)))
                .clipShape(Circle())
            })
            .isHidden(viewConfig.isHidden(elementId: .globalSearchButton), remove: true)
            .accessibilityIdentifier(AccessibilityID.Social.SocialHomePage.globalSearchButton)
            
            if selectedTab != .explore {
                Button(action: {
                    
                    if selectedTab == .myCommunities {
                        goToCommunitySetupPage()
                    } else {
                        withoutAnimation {
                            showPostCreationMenu.toggle()
                        }
                    }
                    
                }, label: {
                    VStack {
                        let createButtonIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .postCreationButton, key: "icon", of: String.self) ?? "")
                        Image(createButtonIcon)
                            .frame(size: CGSize(width: 21.0, height: 16.0))
                    }
                    .frame(size: CGSize(width: 32.0, height: 32.0))
                    .background(Color(viewConfig.theme.secondaryColor.blend(.shade4)))
                    .clipShape(Circle())
                    .accessibilityIdentifier(AccessibilityID.Social.SocialHomePage.postCreationButton)
                })
                .fullScreenCover(isPresented: $showPostCreationMenu) {
                    AmityCreatePostMenuComponent(isPresented: $showPostCreationMenu, pageId: pageId)
                        .background(ClearBackgroundView())
                }
                .isHidden(viewConfig.isHidden(elementId: .postCreationButton), remove: true)
            }
        }
        .padding([.leading, .trailing], 15.5)
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    
    private func goToCommunitySetupPage() {
        let context = AmitySocialHomeTopNavigationComponentBehavior.Context(component: self)
        AmityUIKitManagerInternal.shared.behavior.socialHomeTopNavigationComponentBehavior?.goToCreateCommunityPage(context: context)
    }
    
    struct NotificationIndicator: View {
        @EnvironmentObject var viewConfig: AmityViewConfigController
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(Color(viewConfig.theme.backgroundColor), lineWidth: 4)
                    .frame(width: 10, height: 10)
                
                Circle()
                    .fill(Color(viewConfig.theme.alertColor))
                    .frame(width: 10, height: 10)
            }
        }
    }
}

class SocialHomePageNavigationViewModel: ObservableObject {
    private let trayManager = NotificationTrayManager()
    private var timer: Timer?
    private var token: AmityNotificationToken?
    private let invitationManager = InvitationManager()
    private var invitaionsToken: AmityNotificationToken?
    
    let timerInterval: TimeInterval = 60
    
    @Published var hasUnseenNotification = false
    @Published var hasInvitations = false
    
    func observeNotificationStatus() {
        if timer == nil {
            // Trigger first fetch
            self.checkNotificationStatus()
            
            // Schedule it
            let jitter = Double.random(in: 0...1)
            timer = Timer.scheduledTimer(withTimeInterval: timerInterval + jitter, repeats: true, block: { [weak self] timer in
                self?.checkNotificationStatus()
            })
        }
    }
    
    private func checkNotificationStatus() {
        // Note:
        // Live Object life cycle is tied to its token. If the token is invalidated or nil before the observer is notified, we will never get notification tray seen info.
        // So even though the timer triggers every 1 seconds, we wait for the previous observer to be notified
        // before sending the new request.
        guard token == nil else { return }
        
        let cleanupToken = { [weak self] in
            self?.token?.invalidate()
            self?.token = nil
        }
        
        token = trayManager.getNotificationTraySeenInfo().observe { [weak self] liveObject, error in
            guard let self else { return }
            
            if let _ = error {
                cleanupToken()
                return
            }
            
            guard let snapshot = liveObject.snapshot else {
                cleanupToken()
                return
            }
            
            self.hasUnseenNotification = !snapshot.isSeen

            cleanupToken()
        }
        
        invitaionsToken = invitationManager.getMyCommunityInvitations().observe { [weak self] collection, _ , error in
            guard let self else { return }
            hasInvitations = collection.snapshots.contains { $0.isSeen() == false }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.invitaionsToken?.invalidate()
            self.invitaionsToken = nil
        }
    }
    
    func resetNotificationStatus() {
        // Hacky way to merge invitaion status with notification status
        hasInvitations = false
        
        guard hasUnseenNotification else { return }
        
        // To hide red dot once user opens up notification tray
        hasUnseenNotification = false
    }
}

#if DEBUG
#Preview {
    AmitySocialHomeTopNavigationComponent(pageId: nil)
}
#endif
