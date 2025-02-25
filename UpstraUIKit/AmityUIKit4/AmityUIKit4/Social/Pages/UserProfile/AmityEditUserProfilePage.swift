//
//  AmityEditUserProfilePage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/23/24.
//

import SwiftUI
import AVKit

public struct AmityEditUserProfilePage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .editUserProfilePage
    }
    
    private let userId: String
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var displayNameTextFieldModel = InfoTextFieldModel(
        title: "Display name",
        placeholder: "Display name",
        isMandatory: false,
        isExpandable: true,
        maxCharCount: 100
    )
    @State private var displayNameText: String = ""

    @State private var aboutTextFieldModel = InfoTextFieldModel(
        title: "About",
        placeholder: "About",
        isMandatory: false,
        showOptionalTitle: true,
        isExpandable: true,
        maxCharCount: 180
    )
    @State private var aboutText: String = ""
    @State private var isTextVaild: Bool = true
    @StateObject private var viewModel: AmityEditUserProfilePageViewModel
    @State private var showImagePicker: (isShown: Bool, mediaType: [UTType] , sourceType:  UIImagePickerController.SourceType) = (false, [UTType.image], .photoLibrary)
    @StateObject private var imagePickerViewModel: ImageVideoPickerViewModel = ImageVideoPickerViewModel()
    @State private var isExistingDataChanged: Bool = false
    
    public init() {
        self.userId = AmityUIKitManagerInternal.shared.currentUserId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .editUserProfilePage))
        self._viewModel = StateObject(wrappedValue: AmityEditUserProfilePageViewModel(userId: AmityUIKitManagerInternal.shared.currentUserId))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            navigationBarView
            ScrollView {
                VStack(spacing: 24) {
                    userProifleAvatarView
                    
                    InfoTextField(data: $displayNameTextFieldModel, text: $displayNameText, isValid: $isTextVaild, titleTextAccessibilityId: AccessibilityID.Social.EditUserProfile.userDisplayNameTitle)
                        .alertColor(viewConfig.theme.alertColor)
                        .dividerColor(viewConfig.theme.baseColorShade4)
                        .titleTextColor(viewConfig.theme.baseColor)
                        .infoTextColor(viewConfig.theme.baseColorShade2)
                        .textFieldTextColor(viewConfig.theme.baseColorShade2)
                        .allowsHitTesting(false)
                    
                    InfoTextField(data: $aboutTextFieldModel, text: $aboutText, isValid: $isTextVaild, titleTextAccessibilityId: AccessibilityID.Social.EditUserProfile.userAboutTitle)
                        .alertColor(viewConfig.theme.alertColor)
                        .dividerColor(viewConfig.theme.baseColorShade4)
                        .infoTextColor(viewConfig.theme.baseColorShade2)
                        .textFieldTextColor(viewConfig.theme.baseColor)
                    
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .dismissKeyboardOnDrag()
            
            saveButtonView
                .padding(.bottom, 10)
        }
        .onReceive(viewModel.$user) { user in
            let userDisplayNameTitle = viewConfig.getConfig(elementId: .userDisplayNameTitle, key: "text", of: String.self) ?? "Display Name"
            displayNameTextFieldModel = InfoTextFieldModel(
                title: userDisplayNameTitle,
                placeholder: "Display Name",
                isMandatory: false,
                isExpandable: true,
                maxCharCount: 100
            )
            displayNameText = user?.displayName ?? ""
            
            let aboutTitle = viewConfig.getConfig(elementId: .userAboutTitle, key: "text", of: String.self) ?? "About"
            aboutTextFieldModel = InfoTextFieldModel(
                title: aboutTitle,
                placeholder: aboutTitle,
                isMandatory: false,
                showOptionalTitle: true,
                isExpandable: true,
                maxCharCount: 180
            )
            aboutText = user?.about ?? ""
        }
        .padding(.horizontal, 16)
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .fullScreenCover(isPresented: $showImagePicker.isShown) {
            ImageVideoCameraPicker(viewModel: imagePickerViewModel, mediaType: $showImagePicker.mediaType, sourceType: $showImagePicker.sourceType)
                .ignoresSafeArea()
        }
        .onChange(of: imagePickerViewModel) { _ in
            validateDataChanged()
        }
        .onChange(of: aboutText) { _ in
            validateDataChanged()
        }
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
    }
    
    @ViewBuilder
    private var navigationBarView: some View {
        let title = viewConfig.getConfig(elementId: .title, key: "text", of: String.self) ?? "Edit Profile"
        AmityNavigationBar(title: title, leading: {
            let backButton = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .backButtonElement, key: "image", of: String.self) ?? "")
            Image(backButton)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .frame(width: 24, height: 20)
                .onTapGesture {
                    let alert = UIAlertController(title: AmityLocalizedStringSet.Social.userProfileEditAlertTitle.localizedString, message: AmityLocalizedStringSet.Social.userProfileEditAlertMessage.localizedString, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel)
                    let discardAction = UIAlertAction(title: AmityLocalizedStringSet.General.discard.localizedString, style: .destructive) { _ in
                        host.controller?.navigationController?.popViewController()
                    }
                    
                    alert.addAction(cancelAction)
                    alert.addAction(discardAction)
                    
                    host.controller?.present(alert, animated: true)
                }
        }, trailing: { EmptyView() })
    }
    
    @ViewBuilder
    private var userProifleAvatarView: some View {
        ZStack {
            AmityUserProfileImageView(displayName: viewModel.user?.displayName ?? "", avatarURL: URL(string: viewModel.user?.avatarURL ?? ""))
            
            if let image = imagePickerViewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            }
        
            Color.black
                .opacity(0.4)
            
            Image(AmityIcon.cameraIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .frame(width: 20, height: 16)
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
        .onTapGesture {
            showImagePicker.isShown.toggle()
        }
    }
    
    @ViewBuilder
    private var saveButtonView: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
            
            Rectangle()
                .fill(isExistingDataChanged ? .blue : Color(viewConfig.theme.baseColorShade4))
                .frame(height: 40)
                .cornerRadius(4)
                .overlay (
                    ZStack {
                        let updateButtonText = viewConfig.getConfig(elementId: .updateUserProfileButton, key: "text", of: String.self) ?? "Save"
                        Text(updateButtonText)
                            .applyTextStyle(.bodyBold(isExistingDataChanged ? .white : .gray))
                    }
                )
                .onTapGesture {
                    guard isExistingDataChanged else { return }
                    Task { @MainActor in
                        do {
                            try await viewModel.updateUser(UserModel(about: aboutText, avatar: imagePickerViewModel.selectedImage))
                            Toast.showToast(style: .success, message: "Successfully updated your profile!")
                            host.controller?.navigationController?.popViewController()
                        } catch {
                            Toast.showToast(style: .warning, message: "Failed to save your profile. Please try again.")
                        }
                    }
                }
                .accessibilityIdentifier(AccessibilityID.Social.EditUserProfile.updateUserProfileButton)
        }
    }
    
    private func validateDataChanged(){
        isExistingDataChanged = imagePickerViewModel.selectedImage != nil || aboutText != viewModel.user?.about ?? ""
    }
}
