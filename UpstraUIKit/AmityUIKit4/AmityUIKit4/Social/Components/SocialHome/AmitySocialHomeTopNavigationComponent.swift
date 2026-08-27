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
            let headerLabel = viewConfig.forElement(.headerLabel).text ?? AmityLocalizedStringSet.Social.community.localizedString
            Text(headerLabel)
                .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))
                .padding([.top, .bottom], 15.5)
                .isHidden(viewConfig.isHidden(elementId: .headerLabel), remove: true)
                .accessibilityIdentifier(AccessibilityID.Social.SocialHomePage.headerLabel)
            
            Spacer()
            
            if !AmityUIKitManagerInternal.shared.isGuestUser {
                // Notification Bell Button
                TopNavigationIconButton(elementId: .notificationTrayButton) {
                    notificationButtonAction?()
                    
                    viewModel.resetNotificationStatus()
                }
                .overlay(
                    NotificationIndicator()
                        .offset(x: 13, y: -12)
                        .visibleWhen(viewModel.hasUnseenNotification)
                )
                .onAppear {
                    viewModel.observeNotificationStatus()
                }
            }
            
            // Search Button
            TopNavigationIconButton(elementId: .globalSearchButton) {
                searchButtonAction?()
            }
            .isHidden(viewConfig.isHidden(elementId: .globalSearchButton), remove: true)
            
            // Add Button
            if selectedTab != .explore && !AmityUIKitManagerInternal.shared.isGuestUser {
                TopNavigationIconButton(elementId: .postCreationButton) {
                    withoutAnimation {
                        showPostCreationMenu.toggle()
                    }
                }
                .fullScreenCover(isPresented: $showPostCreationMenu) {
                    AmityCreatePostMenuComponent(isPresented: $showPostCreationMenu, pageId: pageId)
                        .background(ClearBackgroundView())
                }
                .isHidden(viewConfig.isHidden(elementId: .postCreationButton), remove: true)
            }
        }
        .padding([.leading, .trailing], 16)
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
    
    struct TopNavigationIconButton: View {
        
        @EnvironmentObject var viewConfig: AmityViewConfigController
        
        let elementId: ElementId
        let action: () -> Void
        
        init(elementId: ElementId, action: @escaping () -> Void) {
            self.elementId = elementId
            self.action = action
        }
        
        var body: some View {
            Button {
                action()
            } label: {
                let icon = AmityIcon.getImageResource(named: viewConfig.forElement(elementId).icon ?? "")
                VStack {
                    Image(icon)
                        .renderingMode(.template)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(size: CGSize(width: 21.0, height: 16.0))
                }
                .frame(size: CGSize(width: 32.0, height: 32.0))
                .background(Color(viewConfig.theme.baseColorShade4))
                .clipShape(Circle())
                .accessibilityIdentifier(getAccessibilityID(elementId: elementId))
            }
            .buttonStyle(.plain)
        }
        
        private func getAccessibilityID(elementId: ElementId) -> String {
            switch elementId {
            case .notificationTrayButton:
                AccessibilityID.Social.SocialHomePage.notificationTrayButton
            case .globalSearchButton:
                AccessibilityID.Social.SocialHomePage.globalSearchButton
            case .postCreationButton:
                AccessibilityID.Social.SocialHomePage.postCreationButton
            default:
                AccessibilityID.Social.SocialHomePage.clipsButton
            }
        }
    }
}

class SocialHomePageNavigationViewModel: ObservableObject {
    private let trayManager = NotificationTrayManager()
    private var timer: Timer?
    private var token: AmityNotificationToken?
    
    let timerInterval: TimeInterval = 61
    
    @Published var hasUnseenNotification = false
    
    func observeNotificationStatus() {
        if timer == nil {
            // Trigger first fetch
            self.checkNotificationStatus()
            
            // Schedule it
            timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true, block: { [weak self] timer in
                self?.checkNotificationStatus()
            })
        }
    }
    
    private func checkNotificationStatus() {
        // Replace the previous cycle's observation rather than waiting for it to finish. The token
        // is kept alive for the whole interval so every emission updates the dot, including the
        // fresh value that arrives after an initial local one.
        token?.invalidate()
        
        token = trayManager.getNotificationTraySeenInfo().observe { [weak self] liveObject, error in
            guard let self else { return }
            
            // Seen state is unknown, so surface the dot rather than silently hiding it.
            if error != nil {
                self.hasUnseenNotification = true
                return
            }
            
            guard let snapshot = liveObject.snapshot else { return }
            
            self.hasUnseenNotification = !snapshot.isSeen
        }
    }
    
    func resetNotificationStatus() {
        guard hasUnseenNotification else { return }
        
        // To hide red dot once user opens up notification tray.
        // The tray page itself calls markTraySeen on appear, which also covers entry points
        // that bypass this button, such as a deep link into AmityNotificationTrayPage.
        hasUnseenNotification = false
    }
}
