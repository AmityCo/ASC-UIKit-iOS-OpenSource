//
//  AmityCommunitySetupPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/5/24.
//

import SwiftUI
import AmitySDK
import AVKit

public enum AmityCommunitySetupPageMode: Equatable {
    public static func == (lhs: AmityCommunitySetupPageMode, rhs: AmityCommunitySetupPageMode) -> Bool {
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
    @StateObject private var viewModel: AmityCommunitySetupPageViewModel = AmityCommunitySetupPageViewModel()
    
    /// Community Avarta data
    @State private var showBottomSheet: Bool = false
    @State private var showImagePicker: (isShown: Bool, mediaType: [UTType] , sourceType:  UIImagePickerController.SourceType) = (false, [UTType.image], .photoLibrary)
    @StateObject private var imagePickerViewModel: ImageVideoPickerViewModel = ImageVideoPickerViewModel()
    
    /// Community Name data
    @State private var nameTextFieldModel: InfoTextFieldModel = InfoTextFieldModel(title: "Community name", placeholder: "Name your community", isMandatory: false, maxCharCount: 30)
    @State private var nameText: String = ""
    @State private var isTextValid: Bool = true
    
    /// About data
    @State private var aboutTextFieldModel: InfoTextFieldModel = InfoTextFieldModel(title: "About", placeholder: "Enter Description", isMandatory: false, showOptionalTitle: true, isExpandable: true, maxCharCount: 180)
    @State private var aboutText: String = ""
    
    /// Categories data
    @State private var categoryTextFieldModel = InfoTextFieldModel(title: "Categories", placeholder: "Select Category", isMandatory: false, showOptionalTitle: true)
    @State private var categoryText: String = ""
    @State private var selectedCategories: [AmityCommunityCategoryModel] = []
    
    /// Public|Private data
    @State private var isPublicCommunity: Bool = true
    
    /// Add Member data
    @State private var selectedMembers: [AddMemberModel] = [AddMemberModel(type: .create)]
    @State private var enableTouchEvent: Bool = true
    
    /// Track data changes in editMode
    @State private var isExistingDataChanged: Bool = false
    
    public init(mode: AmityCommunitySetupPageMode) {
        self.pageMode = mode
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communitySetupPage))
        
        if case .edit(let community) = mode {
            self._nameText = State(initialValue: community.displayName)
            self._aboutText = State(initialValue: community.communityDescription)
            self._selectedCategories = State(initialValue: community.categories.map { AmityCommunityCategoryModel(object: $0) })
            self._isPublicCommunity = State(initialValue: community.isPublic)
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
                                            AsyncImage(url: URL(string: community.avatar?.largeFileURL ?? ""))
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
                                InfoTextField(data: $nameTextFieldModel, text: $nameText, isValid: $isTextValid)
                                    .alertColor(viewConfig.theme.alertColor)
                                    .dividerColor(viewConfig.theme.baseColorShade4)
                                    .infoTextColor(viewConfig.theme.baseColorShade2)
                                    .textFieldTextColor(viewConfig.theme.baseColor)
                                
                                InfoTextField(data: $aboutTextFieldModel, text: $aboutText, isValid: $isTextValid)
                                    .alertColor(viewConfig.theme.alertColor)
                                    .dividerColor(viewConfig.theme.baseColorShade4)
                                    .infoTextColor(viewConfig.theme.baseColorShade2)
                                    .textFieldTextColor(viewConfig.theme.baseColor)
                                
                                getAddCategoryView()

                                VStack(spacing: 16) {
                                    HStack {
                                        Text("Privacy")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(Color(viewConfig.theme.baseColor))
                                        
                                        Spacer()
                                    }
                                    
                                    PrivacyRadioButtonView(isSelected: isPublicCommunity, icon: AmityIcon.globeIcon.getImageResource(), title: "Public", description: "Anyone can join, view, and search the posts in this community.")
                                        .onTapGesture {
                                            isPublicCommunity = true
                                        }
                                    
                                    PrivacyRadioButtonView(isSelected: !isPublicCommunity, icon: AmityIcon.lockBlackIcon.getImageResource(), title: "Private", description: "Only members invited by the moderators can join, view, and search the posts in this community.")
                                        .onTapGesture {
                                            isPublicCommunity = false
                                        }
                                }
                                
                                Rectangle()
                                    .fill(Color(viewConfig.theme.baseColorShade4))
                                    .frame(height: 1)
                                    .isHidden(isPublicCommunity, remove: false)
                                
                                getAddMemberView(geometry)
                                    .isHidden(isPublicCommunity || pageMode != .create, remove: true)
                                    .id("AddMemberView")
                                    .onChange(of: isPublicCommunity) { _ in
                                        scrollView.scrollTo("AddMemberView", anchor: .bottom)
                                    }
                                    .padding(.bottom, 16) // need to set padding to this view directly to have padding in autoscrolling
                            }
                            .padding([.leading, .trailing], 16)
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { _ in
                                hideKeyboard()
                            }
                    )
                }
            }
            
            
            if case .edit(let community) = pageMode {
                editCommunityButtonView
                    .onTapGesture {
                        guard isExistingDataChanged else { return }
                        editCommunity(community)
                    }
            } else {
                createCommunityButtonView
                    .onTapGesture {
                        guard !nameText.isEmpty else { return }
                        createCommunity()
                    }
            }
        }
        .onChange(of: imagePickerViewModel) { _ in
            validateDataChanged()
        }
        .onChange(of: nameText) { _ in
            validateDataChanged()
        }
        .onChange(of: aboutText) { _ in
            validateDataChanged()
        }
        .onChange(of: selectedCategories) { _ in
            validateDataChanged()
        }
        .onChange(of: isPublicCommunity) { _ in
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
            ImageVideoCameraPicker(viewModel: imagePickerViewModel, mediaType: $showImagePicker.mediaType, sourceType: $showImagePicker.sourceType)
                .ignoresSafeArea()
        }
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
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
                    let title = pageMode == .create ? AmityLocalizedStringSet.Social.communitySetupAlertTitle.localizedString :  AmityLocalizedStringSet.Social.communitySetupEditAlertTitle.localizedString
                    let message = pageMode == .create ?  AmityLocalizedStringSet.Social.communitySetupAlertMessage.localizedString :  AmityLocalizedStringSet.Social.communitySetupEditAlertMessage.localizedString
                    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel)
                    let leaveAction = UIAlertAction(title: pageMode == .create ? AmityLocalizedStringSet.General.leave.localizedString : AmityLocalizedStringSet.General.discard.localizedString, style: .destructive) { action in
                        host.controller?.navigationController?.popViewController(animation: .presentation)
                    }
                    
                    alertController.addAction(cancelAction)
                    alertController.addAction(leaveAction)
                    host.controller?.present(alertController, animated: true)
                }
            
            Spacer()
            
            Text(pageMode == .create ? "Create Communiy" : "Edit Community")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(viewConfig.theme.baseColor))
            
            Spacer()
            
            Color.clear
                .frame(width: 24, height: 24)
        }
    }
    
    
    @ViewBuilder
    private func getAddCategoryView() -> some View {
        if selectedCategories.isEmpty {
            ZStack {
                ZStack(alignment: .trailing) {
                    Image(AmityIcon.arrowIcon.getImageResource())
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                        .frame(width: 18, height: 18)
                        .offset(y: 10)
                    
                    InfoTextField(data: $categoryTextFieldModel, text: $categoryText, isValid: $isTextValid)
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
                let context = AmityCommunitySetupPageBehavior.Context(page: self, selectedCategories: selectedCategories, onCategoryAddedAction: { categories in
                    self.selectedCategories = categories
                })
                AmityUIKitManagerInternal.shared.behavior.communitySetupPageBehavior?.goToAddCategoryPage(context)
            }
        } else {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Categories")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Spacer()
                }
                
                VStack(spacing: 16) {
                    ZStack(alignment: .topTrailing) {
                        CategoryGridView(categories: $selectedCategories)
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
                                let context = AmityCommunitySetupPageBehavior.Context(page: self, selectedCategories: selectedCategories, onCategoryAddedAction: { categories in
                                    self.selectedCategories = categories
                                })
                                AmityUIKitManagerInternal.shared.behavior.communitySetupPageBehavior?.goToAddCategoryPage(context)
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
                Text("Member")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                
                Spacer()
            }
            
            let columns = self.columns(for: geometry.size.width, itemWidth: 68, spacing: 0)
            
            LazyVGrid(columns: columns, content: {
                ForEach(Array(selectedMembers.enumerated()), id: \.element.id) { index, member in
                    switch member.type {
                        
                    case .user:
                        VStack(spacing: 8) {
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(placeholder: AmityIcon.Chat.chatAvatarPlaceholder.imageResource, url: URL(string: member.user?.avatarURL ?? ""))
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                
                                Circle()
                                    .fill(.black.opacity(0.3))
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Image(AmityIcon.closeIcon.getImageResource())
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 18, height: 18)
                                    )
                                    .offset(x: 2, y: -3)
                                    .onTapGesture {
                                        selectedMembers.remove(at: index)
                                    }
                            }
                            
                            
                            Text(member.user?.displayName ?? "Unknown")
                                .font(.system(size: 13))
                                .lineLimit(1)
                                .foregroundColor(Color(viewConfig.theme.baseColor))
                        }
                        .frame(width: 64, height: 68)
                        
                    case .create:
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color(viewConfig.theme.baseColorShade4))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(AmityIcon.plusIcon.getImageResource())
                                        .renderingMode(.template)
                                        .resizable()
                                        .foregroundColor(Color(viewConfig.theme.baseColor))
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 20, height: 20)
                                )
                            
                            Text("Add")
                                .font(.system(size: 13))
                                .lineLimit(1)
                                .foregroundColor(Color(viewConfig.theme.baseColor))
                        }
                        .frame(width: 64, height: 68)
                        .onTapGesture {
                            let selectedUsers = selectedMembers.compactMap { member in
                                if let user = member.user {
                                    return user
                                }
                                
                                return nil
                            }
                            
                            let context = AmityCommunitySetupPageBehavior.Context(page: self, selectedUsers: selectedUsers, onUserAddedAction: { users in
                                self.selectedMembers = users.map({ user in
                                    AddMemberModel(user: user, type: .user)
                                })
                                self.selectedMembers.append(.init(user: nil, type: .create))
                            })
                            AmityUIKitManagerInternal.shared.behavior.communitySetupPageBehavior?.goToAddMemberPage(context)
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
            
            Rectangle()
                .fill(.blue)
                .frame(height: 40)
                .cornerRadius(4)
                .overlay (
                    HStack(spacing: 8) {
                        Image(AmityIcon.plusIcon.getImageResource())
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20.0, height: 20.0)
                        
                        Text("Create Community")
                            .font(.system(size: 15.0, weight: .semibold))
                            .foregroundColor(.white)
                    }
                )
                .overlay (
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4).opacity(0.5))
                        .isHidden(!nameText.isEmpty)
                )
                .padding([.leading, .trailing], 16)
        }
    }
    
    
    private var editCommunityButtonView: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
            
            Rectangle()
                .fill(.blue)
                .frame(height: 40)
                .cornerRadius(4)
                .overlay (
                    Text("Save")
                        .font(.system(size: 15.0, weight: .semibold))
                        .foregroundColor(.white)
                )
                .overlay (
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4).opacity(0.5))
                        .isHidden(isExistingDataChanged)
                )
                .padding([.leading, .trailing], 16)
        }
    }
    
    
    @ViewBuilder
    private func getBottomSheetView() -> some View {
        VStack(spacing: 28) {
            
            getItemView(image: AmityIcon.cameraAttatchmentIcon.getImageResource(), title: "Camera", onTapAction: {
                /// Delay opening picker view a bit to avoid conflicts of opening & closing fullScreenCover views
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    showImagePicker.sourceType = .camera
                    showImagePicker.isShown = true
                }
                
                showBottomSheet.toggle()
            })
            
            getItemView(image: AmityIcon.photoAttatchmentIcon.getImageResource(), title: "Photo", onTapAction: {
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
    private func getItemView(image: ImageResource, title: String, onTapAction: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(viewConfig.defaultLightTheme.baseColorShade4))
                .frame(width: 32, height: 32)
                .overlay (
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
    
    
    private func columns(for width: CGFloat, itemWidth: CGFloat, spacing: CGFloat) -> [GridItem] {
        return Array(repeating: GridItem(.flexible()), count: Int(width / itemWidth))
    }
    
    
    private func validateDataChanged(){
        if case .edit(let community) = pageMode {
            isExistingDataChanged = !((nameText == community.displayName) && (aboutText == community.communityDescription) && (selectedCategories.elementsEqual(community.categories, by: { lhs, rhs in
                lhs.categoryId == rhs.categoryId
            })) && (isPublicCommunity == community.isPublic) && (imagePickerViewModel.selectedImage == nil))
        }
    }
   
    
    private func createCommunity() {
        Task { @MainActor in
            enableTouchEvent = false
            
            let userIds = selectedMembers.compactMap { member in
                if let user = member.user {
                    return user.userId
                }
                
                return nil
            }
            
            let model = CommunityModel(avatar: imagePickerViewModel.selectedImage,
                                             displayName: nameText,
                                             description: aboutText,
                                             categoryIds: selectedCategories.map { $0.categoryId },
                                             isPublic: isPublicCommunity,
                                             userIds: userIds)
            
            do {
                Toast.showToast(style: .loading, message: "Creating the community.", autoHide: false)
                let community = try await viewModel.createCommunity(model)
                
                let communityProfilePage = AmityCommunityProfilePage(communityId: community.communityId)
                let controller = AmitySwiftUIHostingController(rootView: communityProfilePage)
                
                // Get the current view controllers stack
                if var viewControllers = host.controller?.navigationController?.viewControllers {
                    viewControllers.removeLast()
                    viewControllers.append(controller)
                    
                    // Set the updated stack
                    host.controller?.navigationController?.setViewControllers(viewControllers, animated: true)
                    Toast.showToast(style: .success, message: "Successfully created community!")
                }

            } catch {
                Log.add(event: .error, error.localizedDescription)
            }
            
            enableTouchEvent = true
        }
        
    }
    
    
    private func editCommunity(_ community: AmityCommunity) {
        Task { @MainActor in
            enableTouchEvent = false
            
            let model = CommunityModel(avatar: imagePickerViewModel.selectedImage,
                                             displayName: nameText,
                                             description: aboutText,
                                             categoryIds: selectedCategories.map { $0.categoryId },
                                             isPublic: isPublicCommunity)
            
            do {
                Toast.showToast(style: .loading, message: "Updating the community.", autoHide: false)
                let _ = try await viewModel.editCommunity(id: community.communityId, model)
                host.controller?.navigationController?.popViewController(animation: .presentation)
                Toast.showToast(style: .success, message: "Successfully updated community!")
            } catch {
                Log.add(event: .error, error.localizedDescription)
            }
            
            enableTouchEvent = true
        }
    }
    
}



#if DEBUG
#Preview(body: {
    AmityCommunitySetupPage(mode: .create)
})
#endif
