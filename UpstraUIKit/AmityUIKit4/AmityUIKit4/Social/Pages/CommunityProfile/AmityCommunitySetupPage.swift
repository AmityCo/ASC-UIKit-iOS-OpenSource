//
//  AmityCommunitySetupPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/5/24.
//

import AVKit
import AmitySDK
import SwiftUI

public enum AmityCommunitySetupPageMode: Equatable {
    public static func == (lhs: AmityCommunitySetupPageMode, rhs: AmityCommunitySetupPageMode)
    -> Bool
    {
        switch (lhs, rhs) {
        case (.create, .create),
            (.edit, .edit):
            return true
        default:
            return false
        }
    }
    
    case create
    case edit(AmityCommunity)
}

public struct AmityCommunitySetupPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .communitySetupPage
    }
    
    private let pageMode: AmityCommunitySetupPageMode
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityCommunitySetupPageViewModel
    
    /// Community Avatar data
    @State private var showBottomSheet: Bool = false
    @State private var showImagePicker:
    (isShown: Bool, mediaType: [UTType], sourceType: UIImagePickerController.SourceType) = (
        false, [UTType.image], .photoLibrary
    )
    @StateObject private var imagePickerViewModel: ImageVideoPickerViewModel =
    ImageVideoPickerViewModel()
    
    /// Community Name data
    @State private var nameTextFieldModel: InfoTextFieldModel = InfoTextFieldModel(
        title: "Community name", placeholder: "Name your community", isMandatory: false,
        maxCharCount: 30)
    @State private var isTextValid: Bool = true
    
    /// About data
    @State private var aboutTextFieldModel: InfoTextFieldModel = InfoTextFieldModel(
        title: "About", placeholder: "Enter Description", isMandatory: false,
        showOptionalTitle: true, isExpandable: true, maxCharCount: 180)
    
    /// Categories data
    @State private var categoryTextFieldModel = InfoTextFieldModel(
        title: "Categories", placeholder: "Select Category", isMandatory: false,
        showOptionalTitle: true)
    @State private var categoryText: String = ""
    
    /// Add Member data
    @State private var selectedMembers: [AddMemberModel] = [AddMemberModel(type: .create)]
    @State private var enableTouchEvent: Bool = true
    
    /// Track data changes in editMode & create mode
    @State private var isExistingDataChanged: Bool = false
    
    /// Members need to be invited if network setting is invitation mode
    @State private var isMembershipInvitationEnabled: Bool = false
    
    // Draft contains all information inputted by user in this setup page
    @StateObject var draft: CommunityDraft
    
    public init(mode: AmityCommunitySetupPageMode) {
        self.pageMode = mode
        self._viewConfig = StateObject(
            wrappedValue: AmityViewConfigController(pageId: .communitySetupPage))
        self._viewModel = StateObject(
            wrappedValue: AmityCommunitySetupPageViewModel(mode: mode, communityId: nil))
        
        if let setting = AmityUIKitManagerInternal.shared.client.getSocialSettings()?
            .membershipAcceptance
        {
            self._isMembershipInvitationEnabled = State(initialValue: setting == .invitation)
        }
        
        if case .edit(let community) = mode {
            self._draft = StateObject(wrappedValue: CommunityDraft(community: community))
            self._viewModel = StateObject(
                wrappedValue: AmityCommunitySetupPageViewModel(
                    mode: mode, communityId: community.communityId))
        } else {
            self._draft = StateObject(wrappedValue: CommunityDraft())
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            navigationBarView
                .padding(EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 12))
            
            GeometryReader { geometry in
                ScrollViewReader { scrollView in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Color(viewConfig.theme.baseColorShade3)
                                .overlay(
                                    ZStack {
                                        if case .edit(let community) = pageMode {
                                            AsyncImage(
                                                url: URL(
                                                    string: community.avatar?.largeFileURL ?? ""))
                                        }
                                        
                                        if let image = imagePickerViewModel.selectedImage {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .clipped()
                                        }
                                        
                                        Color.black
                                            .opacity(0.25)
                                        
                                        Image(AmityIcon.cameraIcon.getImageResource())
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 28)
                                    }
                                )
                                .clipped()
                                .contentShape(Rectangle())
                                .frame(height: 188)
                                .onTapGesture {
                                    showBottomSheet.toggle()
                                }
                            
                            VStack(alignment: .leading, spacing: 24) {
                                // Community Name
                                InfoTextField(
                                    data: $nameTextFieldModel, text: $draft.name,
                                    isValid: $isTextValid,
                                    titleTextAccessibilityId: AccessibilityID.Social.CommunitySetup
                                        .communityNameTitle
                                )
                                .alertColor(viewConfig.theme.alertColor)
                                .dividerColor(viewConfig.theme.baseColorShade4)
                                .infoTextColor(viewConfig.theme.baseColorShade2)
                                .textFieldTextColor(viewConfig.theme.baseColor)
                                
                                // Community Description
                                InfoTextField(
                                    data: $aboutTextFieldModel, text: $draft.about,
                                    isValid: $isTextValid,
                                    titleTextAccessibilityId: AccessibilityID.Social.CommunitySetup
                                        .communityAboutTitle
                                )
                                .alertColor(viewConfig.theme.alertColor)
                                .dividerColor(viewConfig.theme.baseColorShade4)
                                .infoTextColor(viewConfig.theme.baseColorShade2)
                                .textFieldTextColor(viewConfig.theme.baseColor)
                                
                                // Categories
                                getAddCategoryView()
                                
                                // Privacy
                                VStack(spacing: 16) {
                                    HStack {
                                        let privacyTitle =
                                        viewConfig.getText(elementId: .communityPrivacyTitle)
                                        ?? ""
                                        Text(privacyTitle)
                                            .applyTextStyle(
                                                .titleBold(Color(viewConfig.theme.baseColor))
                                            )
                                            .accessibilityIdentifier(
                                                AccessibilityID.Social.CommunitySetup
                                                    .communityPrivacyTitle)
                                        
                                        Spacer()
                                    }
                                    
                                    let publicTitle =
                                    viewConfig.getText(elementId: .communityPrivacyPublicTitle)
                                    ?? ""
                                    let publicDesc =
                                    viewConfig.getText(
                                        elementId: .communityPrivacyPublicDescription) ?? ""
                                    let publicIcon = viewConfig.getImage(
                                        elementId: .communityPrivacyPublicIcon)
                                    PrivacyRadioButtonView(
                                        isSelected: draft.privacy == .public, icon: publicIcon,
                                        title: publicTitle, description: publicDesc
                                    )
                                    .onTapGesture {
                                        if pageMode == .create {
                                            draft.requiresModeratorApproval = false
                                        }
                                        
                                        draft.privacy = .public
                                    }
                                    .accessibilityIdentifier(
                                        AccessibilityID.Social.CommunitySetup
                                            .communityPrivacyPublicTitle)
                                    
                                    PrivacyRadioButtonView(
                                        isSelected: draft.privacy == .privateAndVisible,
                                        icon: AmityIcon.globePrivateIcon.imageResource,
                                        title: "Private & visible",
                                        description:
                                            "Community is discoverable by anyone. Content is hidden from non-members."
                                    )
                                    .onTapGesture {
                                        if pageMode == .create {
                                            draft.requiresModeratorApproval = true
                                        }
                                        draft.privacy = .privateAndVisible
                                    }

                                    let privateIcon = viewConfig.getImage(
                                        elementId: .communityPrivacyPrivateIcon)
                                    PrivacyRadioButtonView(
                                        isSelected: draft.privacy == .privateAndHidden,
                                        icon: privateIcon, title: "Private & hidden",
                                        description:
                                            "Community and content are hidden from non-members, and cannot be discovered via search."
                                    )
                                    .onTapGesture {
                                        if pageMode == .create {
                                            draft.requiresModeratorApproval = true
                                        }
                                        draft.privacy = .privateAndHidden
                                    }
                                    .accessibilityIdentifier(
                                        AccessibilityID.Social.CommunitySetup
                                            .communityPrivacyPrivateTitle)
                                }
                                
                                Rectangle()
                                    .fill(Color(viewConfig.theme.baseColorShade4))
                                    .frame(height: 1)
                                
                                VStack(spacing: 16) {
                                    let communityMembershipTitle = viewConfig.getText(elementId: .communityMembershipTitle) ?? ""
                                    HStack {
                                        Text(communityMembershipTitle)
                                            .applyTextStyle(
                                                .titleBold(Color(viewConfig.theme.baseColor)))
                                        
                                        Spacer()
                                    }
                                    
                                    HStack(spacing: 10) {
                                        let commMembershipDescription = viewConfig.getText(elementId: .communityMembershipDescription) ?? ""
                                        VStack(spacing: 6) {
                                            Text(commMembershipDescription)
                                                .applyTextStyle(
                                                    .bodyBold(Color(viewConfig.theme.baseColor))
                                                )
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            let commMembershipSubDescription = viewConfig.getText(elementId: .communityMembershipSubDescription) ?? ""
                                            Text(commMembershipSubDescription)
                                            .applyTextStyle(
                                                .caption(Color(viewConfig.theme.baseColorShade1))
                                            )
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        
                                        Toggle("", isOn: $draft.requiresModeratorApproval)
                                            .toggleStyle(
                                                SwitchToggleStyle(
                                                    tint: Color(viewConfig.theme.primaryColor))
                                            )
                                            .frame(width: 48, height: 28)
                                    }
                                    .contentShape(Rectangle())
                                }
                                
                                Rectangle()
                                    .fill(Color(viewConfig.theme.baseColorShade4))
                                    .frame(height: 1)
                                    .isHidden(draft.privacy == .public, remove: false)
                                
                                if isMembershipInvitationEnabled {
                                    getInviteMemberView(geometry)
                                        .isHidden(draft.privacy == .public || pageMode != .create, remove: true) // Hide member view while editing public community
                                        .id("InviteMemberView")
                                        .onChange(of: draft.privacy) { _ in
                                            guard draft.privacy == .privateAndVisible else { return }
                                            
                                            scrollView.scrollTo("InviteMemberView", anchor: .bottom)
                                        }
                                        .padding(.bottom, 16)
                                } else {
                                    getAddMemberView(geometry)
                                        .isHidden(draft.privacy == .public || pageMode != .create, remove: true) // Hide member view while editing public community
                                        .id("AddMemberView")
                                        .onChange(of: draft.privacy) { _ in
                                            scrollView.scrollTo("AddMemberView", anchor: .bottom)
                                        }
                                        .padding(.bottom, 16)  // need to set padding to this view directly to have padding in autoscrolling
                                }
                            }
                            .padding([.leading, .trailing], 16)
                        }
                    }
                }
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in
                        hideKeyboard()
                    }
            )
            
            if case .edit(let community) = pageMode {
                editCommunityButtonView(community: community)
            } else {
                createCommunityButtonView
            }
        }
        .onChange(of: imagePickerViewModel) { _ in
            validateDataChanged()
        }
        .onChange(of: draft) { _ in
            validateDataChanged()
        }
        .allowsHitTesting(enableTouchEvent)
        .background(Color(viewConfig.theme.backgroundColor))
        .environmentObject(viewConfig)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .bottomSheet(isShowing: $showBottomSheet, height: .fixed(180)) {
            getBottomSheetView()
        }
        .fullScreenCover(isPresented: $showImagePicker.isShown) {
            ImageVideoCameraPicker(
                viewModel: imagePickerViewModel, mediaType: $showImagePicker.mediaType,
                sourceType: $showImagePicker.sourceType
            )
            .ignoresSafeArea()
        }
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
            
            nameTextFieldModel.title = viewConfig.getText(elementId: .communityNameTitle) ?? ""
            aboutTextFieldModel.title = viewConfig.getText(elementId: .communityAboutTitle) ?? ""
            categoryTextFieldModel.title =
            viewConfig.getText(elementId: .communityCategoryTitle) ?? ""
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
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
                    
                    // Do not show alert if existing data is not changed
                    if !isExistingDataChanged {
                        host.controller?.navigationController?.popViewController(
                            animation: .presentation)
                        return
                    }
                    
                    showConfirmationAlert(type: .discard) {
                        host.controller?.navigationController?.popViewController(animation: .presentation)
                    }
                }
            
            Spacer()
            
            let title =
            pageMode == .create
            ? viewConfig.getText(elementId: .title) ?? ""
            : viewConfig.getText(elementId: .communityEditTitle) ?? ""
            Text(title)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .accessibilityIdentifier(AccessibilityID.Social.CommunitySetup.title)
            
            Spacer()
            
            Color.clear
                .frame(width: 24, height: 24)
        }
    }
    
    @ViewBuilder
    private func getAddCategoryView() -> some View {
        if draft.categories.isEmpty {
            ZStack {
                ZStack(alignment: .trailing) {
                    Image(AmityIcon.arrowIcon.getImageResource())
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                        .frame(width: 18, height: 18)
                        .offset(y: 10)
                    
                    InfoTextField(
                        data: $categoryTextFieldModel, text: $categoryText, isValid: $isTextValid,
                        titleTextAccessibilityId: AccessibilityID.Social.CommunitySetup
                            .communityCategoryTitle
                    )
                    .alertColor(viewConfig.theme.alertColor)
                    .dividerColor(viewConfig.theme.baseColorShade4)
                    .infoTextColor(viewConfig.theme.baseColorShade2)
                    .textFieldTextColor(viewConfig.theme.baseColor)
                    .allowsHitTesting(false)
                }
                
                Color.clear
                    .contentShape(Rectangle())
            }
            .onTapGesture {
                let context = AmityCommunitySetupPageBehavior.Context(
                    page: self, selectedCategories: draft.categories,
                    onCategoryAddedAction: { categories in
                        self.draft.categories = categories
                    })
                AmityUIKitManagerInternal.shared.behavior.communitySetupPageBehavior?
                    .goToAddCategoryPage(context)
            }
        } else {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Categories")
                        .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                    
                    Spacer()
                }
                
                VStack(spacing: 16) {
                    ZStack(alignment: .topTrailing) {
                        CategoryGridView(categories: $draft.categories)
                            .environmentObject(viewConfig)
                            .padding(.trailing, 10)
                        
                        Image(AmityIcon.arrowIcon.getImageResource())
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                            .frame(width: 18, height: 18)
                            .offset(y: 10)
                            .onTapGesture {
                                let context = AmityCommunitySetupPageBehavior.Context(
                                    page: self, selectedCategories: draft.categories,
                                    onCategoryAddedAction: { categories in
                                        self.draft.categories = categories
                                    })
                                AmityUIKitManagerInternal.shared.behavior
                                    .communitySetupPageBehavior?.goToAddCategoryPage(context)
                            }
                    }
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 1)
                }
            }
        }
    }
    
    private func getAddMemberView(_ geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                let addMemberTitle = viewConfig.getText(elementId: .communityAddMemberTitle) ?? ""
                Text(addMemberTitle)
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                    .accessibilityIdentifier(
                        AccessibilityID.Social.CommunitySetup.communityAddMemberTitle)
                
                Spacer()
            }
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 4),
                content: {
                    ForEach(Array(selectedMembers.enumerated()), id: \.element.id) {
                        index, member in
                        switch member.type {
                            
                        case .user:
                            SelectedMemberView(member: member) {
                                selectedMembers.remove(at: index)
                            }
                        case .create:
                            AddNewMemberView(elementId: .communityAddMemberButton)
                            .onTapGesture {
                                let selectedUsers = selectedMembers.compactMap { $0.user }
                                
                                let context = AmityCommunitySetupPageBehavior.Context(
                                    page: self, selectedUsers: selectedUsers,
                                    onUserAddedAction: { users in
                                        self.selectedMembers = users.map({ user in
                                            AddMemberModel(user: user, type: .user)
                                        })
                                        self.selectedMembers.append(.init(user: nil, type: .create))
                                    })
                                AmityUIKitManagerInternal.shared.behavior
                                    .communitySetupPageBehavior?.goToAddMemberPage(context)
                            }
                        }
                    }
                })
        }
    }
    
    private func getInviteMemberView(_ geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    let inviteMemberTitle =
                    viewConfig.getText(elementId: .communityInviteMemberTitle) ?? ""
                    Text(inviteMemberTitle)
                        .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                        .accessibilityIdentifier(
                            AccessibilityID.Social.CommunitySetup.communityAddMemberTitle)
                    
                    let inviteMemberDesc =
                    viewConfig.getText(elementId: .communityInviteMemberDescription) ?? ""
                    Text(inviteMemberDesc)
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                }
                
                Spacer()
            }
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 4),
                content: {
                    ForEach(Array(selectedMembers.enumerated()), id: \.element.id) {
                        index, member in
                        switch member.type {
                            
                        case .user:
                            SelectedMemberView(member: member) {
                                selectedMembers.remove(at: index)
                            }
                        case .create:
                            AddNewMemberView(elementId: .communityInviteMemberButton)
                            .onTapGesture {
                                let selectedUsers = selectedMembers.compactMap { $0.user }
                                
                                let context = AmityCommunitySetupPageBehavior.Context(
                                    page: self, selectedUsers: selectedUsers,
                                    onMemberInvitedAction: { users in
                                        self.selectedMembers.removeAll()
                                        self.selectedMembers.append(.init(user: nil, type: .create))
                                        self.selectedMembers.append(
                                            contentsOf: users.map({ user in
                                                AddMemberModel(user: user, type: .user)
                                            }))
                                        self.host.controller?.presentedViewController?.dismiss(animated: true)
                                    })
                                AmityUIKitManagerInternal.shared.behavior
                                    .communitySetupPageBehavior?.goToInviteMemberPage(context)
                            }
                        }
                    }
                })
        }
    }
    
    private var createCommunityButtonView: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
            
            Button {
                guard !draft.name.isEmpty else { return }
                createCommunity()
            } label: {
                HStack(spacing: 8) {
                    let communityCreateButtonImage = viewConfig.getImage(
                        elementId: .communityCreateButton)
                    Image(communityCreateButtonImage)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20.0, height: 20.0)
                    
                    let communityCreateButtonText =
                    viewConfig.getText(elementId: .communityCreateButton) ?? ""
                    Text(communityCreateButtonText)
                        .applyTextStyle(.bodyBold(.white))
                }
            }
            .buttonStyle(AmityPrimaryButtonStyle(viewConfig: viewConfig))
            .disabled(draft.name.isEmpty)
            .padding(.horizontal, 16)
        }
        .accessibilityIdentifier(AccessibilityID.Social.CommunitySetup.communityCreateButton)
    }
    
    private func editCommunityButtonView(community: AmityCommunity) -> some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
            
            Button {
                guard isExistingDataChanged else { return }
                
                let requiredConfirmations = draft.requiresConfirmationForPrivacyChanges(with: CommunityDraft(community: community))
                var isConfirmationAlertShown = false
                
                // Note:
                // We show maximum one confirmation alert (if required) for edit operation. Incase confirmation alert is not required, we continue with editing community
                for confirmation in requiredConfirmations {
                    
                    if confirmation == .pendingJoinRequests {
                        guard viewModel.hasPendingJoinRequests else { continue }
                        
                        isConfirmationAlertShown = true
                        showConfirmationAlert(type: .pendingJoinRequests) {
                            // Do nothing
                        }
                        
                        // Once alert is shown, we break out of the loop
                        break
                    }
                    
                    if confirmation == .globalFeaturedPosts {
                        guard viewModel.hasGlobalPinnedPost else { continue }
                        
                        isConfirmationAlertShown = true
                        showConfirmationAlert(type: .globalFeaturedPosts) {
                            editCommunity(community)
                        }
                        
                        // Once alert is shown, we break out of the loop
                        break
                    }
                }
                
                if !isConfirmationAlertShown {
                    editCommunity(community)
                }
            } label: {
                Text(viewConfig.getText(elementId: .communityEditButton) ?? "Save")
                    .applyTextStyle(.bodyBold(.white))

            }
            .buttonStyle(AmityPrimaryButtonStyle(viewConfig: viewConfig))
            .disabled(!isExistingDataChanged)
            .padding(.horizontal, 16)
        }
        .accessibilityIdentifier(AccessibilityID.Social.CommunitySetup.communityEditButton)
    }
    
    @ViewBuilder
    private func getBottomSheetView() -> some View {
        VStack(spacing: 28) {
            
            let cameraTitle = viewConfig.getText(elementId: .cameraButton) ?? "Camera"
            let cameraImage = viewConfig.getImage(elementId: .cameraButton)
            getItemView(
                image: cameraImage, title: cameraTitle,
                onTapAction: {
                    /// Delay opening picker view a bit to avoid conflicts of opening & closing fullScreenCover views
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        showImagePicker.sourceType = .camera
                        showImagePicker.isShown = true
                    }
                    
                    showBottomSheet.toggle()
                })
            
            let photoTitle = viewConfig.getText(elementId: .imageButton) ?? "Photo"
            let photoImage = viewConfig.getImage(elementId: .imageButton)
            getItemView(
                image: photoImage, title: photoTitle,
                onTapAction: {
                    /// Delay opening picker view a bit to avoid conflicts of opening & closing fullScreenCover views
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        showImagePicker.sourceType = .photoLibrary
                        showImagePicker.isShown = true
                    }
                    
                    showBottomSheet.toggle()
                })
            
            Spacer()
        }
        .padding(.top, 10)
    }
    
    @ViewBuilder
    private func getItemView(image: ImageResource, title: String, onTapAction: @escaping () -> Void)
    -> some View
    {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(viewConfig.defaultLightTheme.baseColorShade4))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                )
                .clipShape(Circle())
            
            Text(title)
                .foregroundColor(Color(viewConfig.theme.baseColor))
            
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.leading, 25)
        .onTapGesture {
            onTapAction()
        }
    }
    
    private func validateDataChanged() {
        if case .edit(let community) = pageMode {
            isExistingDataChanged = draft.hasChanges(with: CommunityDraft(community: community)) || imagePickerViewModel.selectedImage != nil
        }
        
        if case .create = pageMode {
            isExistingDataChanged = draft.hasChanges(with: CommunityDraft()) || imagePickerViewModel.selectedImage != nil || selectedMembers.count > 1
        }
    }
    
    private func createCommunity() {
        Task { @MainActor in
            enableTouchEvent = false
            
            let userIds = selectedMembers.compactMap { $0.user?.userId }
            
            draft.avatar = imagePickerViewModel.selectedImage
            draft.userIds = userIds
            
            do {
                let community = try await viewModel.createCommunity(draft)
                
                // After community creation, invite members if needed
                if isMembershipInvitationEnabled && !userIds.isEmpty {
                    try await viewModel.inviteMembers(userIds, toCommunity: community)
                }
                
                let communityProfilePage = AmityCommunityProfilePage(
                    communityId: community.communityId)
                let controller = AmitySwiftUIHostingController(rootView: communityProfilePage)
                
                // Get the current view controllers stack
                if var viewControllers = host.controller?.navigationController?.viewControllers {
                    viewControllers.removeLast()
                    viewControllers.append(controller)
                    
                    // Set the updated stack
                    host.controller?.navigationController?.setViewControllers(
                        viewControllers, animated: true)
                    Toast.showToast(style: .success, message: "Successfully created community!")
                }
                
            } catch {
                Toast.showToast(style: .warning, message: "Failed to create community!")
            }
            
            enableTouchEvent = true
        }
        
    }
    
    private func editCommunity(_ community: AmityCommunity) {
        Task { @MainActor in
            enableTouchEvent = false
            
            let userIds = selectedMembers.compactMap { $0.user?.userId }
                        
            draft.avatar = imagePickerViewModel.selectedImage
            
            do {
                let _ = try await viewModel.editCommunity(id: community.communityId, draft)
                
                // After community edit, invite members if needed
                if isMembershipInvitationEnabled && !userIds.isEmpty {
                    try await viewModel.inviteMembers(userIds, toCommunity: community)
                }
                
                host.controller?.navigationController?.popToViewController(AmityCommunityProfilePage.self, animated: true)

                Toast.showToast(
                    style: .success,
                    message: AmityLocalizedStringSet.Social.communityUpdateSuccessToastMessage
                        .localizedString)
            } catch {
                Toast.showToast(
                    style: .warning,
                    message: "Failed to save your community profile. Please try again.")
            }
            
            enableTouchEvent = true
        }
    }
    
    func showConfirmationAlert(type: CommunitySetupConfirmation, completion: @escaping () -> Void) {
        let alertController: UIAlertController
        let cancelAction = UIAlertAction(
            title: AmityLocalizedStringSet.General.cancel.localizedString,
            style: .cancel)
        var actions: [UIAlertAction] = []
        
        switch type {
        case .pendingJoinRequests:
            alertController = UIAlertController(
                title: AmityLocalizedStringSet.Social.pendingJoinRequestAlertTitle.localizedString, message: AmityLocalizedStringSet.Social.pendingJoinRequestAlertMessage.localizedString, preferredStyle: .alert)
            
            let confirmAction = UIAlertAction(
                title: AmityLocalizedStringSet.General.okay.localizedString,
                style: .default) { action in
                    completion()
                }
            actions.append(confirmAction)
            
        case .globalFeaturedPosts:
            let title = AmityLocalizedStringSet.Social
                .globalFeaturedCommunityEditConfirmationTitle.localizedString
            let message = AmityLocalizedStringSet.Social
                .globalFeaturedCommunityEditConfirmationMessage.localizedString
            
            let confirmAction = UIAlertAction(
                title: AmityLocalizedStringSet.General.confirm.localizedString,
                style: .destructive
            ) { action in
                completion()
            }
            
            alertController = UIAlertController(
                title: title, message: message, preferredStyle: .alert)
            actions.append(cancelAction)
            actions.append(confirmAction)
        case .discard:
            let title =
            pageMode == .create
            ? AmityLocalizedStringSet.Social.communitySetupAlertTitle.localizedString
            : AmityLocalizedStringSet.Social.communitySetupEditAlertTitle
                .localizedString
            let message =
            pageMode == .create
            ? AmityLocalizedStringSet.Social.communitySetupAlertMessage.localizedString
            : AmityLocalizedStringSet.Social.communitySetupEditAlertMessage
                .localizedString
            let leaveAction = UIAlertAction(
                title: pageMode == .create
                ? AmityLocalizedStringSet.General.leave.localizedString
                : AmityLocalizedStringSet.General.discard.localizedString,
                style: .destructive
            ) { action in
                completion()
            }
            
            alertController = UIAlertController(
                title: title, message: message, preferredStyle: .alert)
            actions.append(cancelAction)
            actions.append(leaveAction)
        }
        
        actions.forEach { action in
            alertController.addAction(action)
        }
        host.controller?.present(alertController, animated: true)
    }
    
    // View showing invited/added members in a circular avatar.
    struct SelectedMemberView: View {
        
        @EnvironmentObject var viewConfig: AmityViewConfigController
        
        let member: AddMemberModel
        let onRemove: () -> Void
        
        var body: some View {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    AmityUserProfileImageView(displayName: member.user?.displayName
                        ?? AmityLocalizedStringSet.General.anonymous
                            .localizedString,
                        avatarURL: URL(string: member.user?.avatarURL ?? "")
                    )
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    
                    Circle()
                        .fill(.black.opacity(0.3))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(AmityIcon.closeIcon.imageResource)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 18, height: 18)
                        )
                        .offset(x: 2, y: -3)
                        .onTapGesture {
                            onRemove()
                        }
                }
                
                let isBrandUser = member.user?.isBrand ?? false
                UserDisplayNameLabel(name: member.user?.displayName ?? "Unknown", isBrand: isBrandUser, textStyle: .caption(Color(viewConfig.theme.baseColor)), spacing: 1)
            }
            .frame(width: 64, height: 68)
        }
    }
    
    struct AddNewMemberView: View {
        @EnvironmentObject var viewConfig: AmityViewConfigController
        
        let elementId: ElementId
        
        var body: some View {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(
                            viewConfig.getImage(
                                elementId: elementId)
                        )
                        .renderingMode(.template)
                        .resizable()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .accessibilityIdentifier(
                            AccessibilityID.Social.CommunitySetup
                                .communityAddMemberButton)
                    )
                
                let title =
                viewConfig.getText(elementId: elementId) ?? ""
                Text(title)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColor)))
                    .lineLimit(1)
            }
            .frame(width: 64, height: 68)
            .contentShape(Rectangle())
        }
    }
}
