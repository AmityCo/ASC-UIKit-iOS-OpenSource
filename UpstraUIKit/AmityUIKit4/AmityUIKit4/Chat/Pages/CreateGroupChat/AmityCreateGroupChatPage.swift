//
//  AmityCreateGroupChatPage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

// MARK: - Alert cases

private enum CreateGroupAlert: Identifiable {
    case leaveConfirm
    case inappropriateImage
    case avatarUploadFailed

    var id: Self { self }
}

// MARK: - Page

public struct AmityCreateGroupChatPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .createGroupChatPage }

    @StateObject private var viewConfig: AmityViewConfigController
    @State private var groupName: String = ""
    @State private var isCreating = false
    @State private var errorMessage: String? = nil
    @State private var isPublic: Bool = true
    @State private var showingAvatarPicker: Bool = false
    @State private var selectedAvatar: UIImage? = nil
    @State private var showingAddMembers: Bool = false
    @State private var activeAlert: CreateGroupAlert? = nil
    @State private var showImageSourceSheet: Bool = false
    @State private var showCameraPicker: Bool = false

    // MARK: - Avatar pre-upload state
    @State private var isUploadingAvatar: Bool = false
    @State private var avatarUploadTask: Task<AmityImageData, Error>? = nil
    @State private var uploadedAvatarImage: UIImage? = nil

    @State private var selectedUsers: [AmityUser]

    private var hasUnsavedInput: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedAvatar != nil
            || !selectedUsers.isEmpty
    }

    public init(selectedUsers: [AmityUser]) {
        self._selectedUsers = State(initialValue: selectedUsers)
        self._viewConfig = StateObject(
            wrappedValue: AmityViewConfigController(pageId: .createGroupChatPage)
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: Nav bar
            navBar

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: Group avatar picker
                    avatarPicker
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)

                    // MARK: Group name
                    groupNameSection
                        .padding(.horizontal, 16)
                        .padding(.top, 24)

                    // MARK: Privacy section
                    privacySection
                        .padding(.horizontal, 16)
                        .padding(.top, 24)

                    // MARK: Warning banner
                    privacyWarningBanner
                        .padding(.top, 20)

                    // MARK: Members section
                    membersSection
                        .padding(.top, 8)
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .navigationBarHidden(true)
        .updateTheme(with: viewConfig)
        .sheet(isPresented: $showingAvatarPicker) {
            ImagePickerView(selectedImage: $selectedAvatar)
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraPickerView(selectedImage: $selectedAvatar)
        }
        .onChange(of: selectedAvatar) { newImage in
            handleAvatarSelectionChange(newImage)
        }
        .bottomSheet(isShowing: $showImageSourceSheet, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
            VStack(spacing: 0) {
                // Camera option
                Button {
                    showImageSourceSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCameraPicker = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(AmityIcon.Chat.cameraButtonIcon.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        Text(AmityLocalizedStringSet.Chat.camera.localizedString)
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                // Photo option
                Button {
                    showImageSourceSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingAvatarPicker = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(AmityIcon.Chat.imageButtonIcon.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        Text(AmityLocalizedStringSet.Chat.EditGroupProfile.avatarLibrary.localizedString)
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 32)
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .leaveConfirm:
                return Alert(
                    title: Text(AmityLocalizedStringSet.Chat.CreateGroup.leaveAlertTitle.localizedString),
                    message: Text(AmityLocalizedStringSet.Chat.CreateGroup.leaveAlertMessage.localizedString),
                    primaryButton: .destructive(Text(AmityLocalizedStringSet.General.leave.localizedString)) {
                        host.controller?.navigationController?.dismiss(animated: true)
                    },
                    secondaryButton: .cancel(Text(AmityLocalizedStringSet.General.cancel.localizedString))
                )
            case .inappropriateImage, .avatarUploadFailed:
                return Alert(
                    title: Text(alert == .inappropriateImage
                        ? AmityLocalizedStringSet.Chat.EditGroupProfile.uploadFailedTitle.localizedString
                        : AmityLocalizedStringSet.Chat.uploadFailedTitle.localizedString),
                    message: Text(alert == .inappropriateImage
                        ? AmityLocalizedStringSet.Chat.EditGroupProfile.uploadFailedMessage.localizedString
                        : AmityLocalizedStringSet.Chat.uploadFailedMessage.localizedString),
                    dismissButton: .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString))
                )
            }
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        ZStack {
            Text(AmityLocalizedStringSet.Chat.CreateGroup.title.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .frame(maxWidth: .infinity)

            HStack {
                Button {
                    if hasUnsavedInput {
                        activeAlert = .leaveConfirm
                    } else {
                        host.controller?.navigationController?.dismiss(animated: true)
                    }
                } label: {
                    Image(AmityIcon.Chat.closeButtonIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 16, height: 16)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    createGroup()
                } label: {
                    Text(AmityLocalizedStringSet.Chat.CreateGroup.createButton.localizedString)
                        .applyTextStyle(.bodyBold(
                            isUploadingAvatar
                                ? Color(viewConfig.theme.highlightColor).opacity(0.5)
                                : Color(viewConfig.theme.highlightColor)))
                }
                .buttonStyle(.plain)
                .disabled(isCreating || isUploadingAvatar)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    // MARK: - Avatar picker

    private var avatarPicker: some View {
        Button {
            showImageSourceSheet = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(viewConfig.theme.highlightColor).opacity(0.2))
                    .frame(width: 120, height: 120)

                if selectedAvatar == nil {
                    Image(AmityIcon.Chat.groupAvatarPlaceholderIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.backgroundColor))
                        .frame(width: 40, height: 40)
                } else if let img = selectedAvatar {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }

                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 120, height: 120)

                if isUploadingAvatar {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                } else {
                    Image(AmityIcon.Chat.cameraIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Group name section

    private var groupNameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(AmityLocalizedStringSet.Chat.CreateGroup.nameLabel.localizedString)
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                Text(AmityLocalizedStringSet.Chat.CreateGroup.nameOptional.localizedString)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade3)))
                Spacer()
                Text("\(groupName.count)/100")
                    .applyTextStyle(.caption(
                        groupName.count > 100
                            ? Color.red
                            : Color(viewConfig.theme.baseColorShade1)
                    ))
            }

            TextField(
                AmityLocalizedStringSet.Chat.CreateGroup.namePlaceholder.localizedString,
                text: $groupName
            )
            .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
            .padding(.vertical, 8)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade3)),
                alignment: .bottom
            )
            .onChange(of: groupName) { newValue in
                if newValue.count > 100 {
                    groupName = String(newValue.prefix(100))
                }
            }

            if let error = errorMessage {
                Text(error)
                    .applyTextStyle(.custom(12, .regular, .red))
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Privacy section

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(AmityLocalizedStringSet.Chat.CreateGroup.privacyTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))

            privacyRow(
                icon: AmityIcon.Chat.createGroupPublicIcon.imageResource,
                title: AmityLocalizedStringSet.Chat.CreateGroup.privacyPublic.localizedString,
                description: AmityLocalizedStringSet.Chat.CreateGroup.privacyPublicDesc.localizedString,
                isSelected: isPublic
            ) {
                isPublic = true
            }

            privacyRow(
                icon: AmityIcon.Chat.createGroupPrivateIcon.imageResource,
                title: AmityLocalizedStringSet.Chat.CreateGroup.privacyPrivate.localizedString,
                description: AmityLocalizedStringSet.Chat.CreateGroup.privacyPrivateDesc.localizedString,
                isSelected: !isPublic
            ) {
                isPublic = false
            }
        }
    }

    private func privacyRow(
        icon: ImageResource,
        title: String,
        description: String,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(width: 40, height: 40)
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    Text(description)
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(lineWidth: 2.0)
                        .fill(.gray)
                        .frame(width: 16, height: 16)
                        .opacity(isSelected ? 0 : 1)
                    
                    Image(AmityIcon.pollRadioIcon.imageResource)
                        .frame(width: 22, height: 22)
                        .opacity(isSelected ? 1 : 0)
                }
            }
        }
        .padding(.vertical, 16)
        .buttonStyle(.plain)
    }

    // MARK: - Privacy warning banner

    private var privacyWarningBanner: some View {
        HStack {
            Text(AmityLocalizedStringSet.Chat.CreateGroup.privacyWarning.localizedString)
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(16)
        .background(Color(viewConfig.theme.backgroundShade1Color))
    }

    // MARK: - Members section

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(AmityLocalizedStringSet.Chat.CreateGroup.memberLabel.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .padding(.horizontal, 16)
                .padding(.top, 8)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 19), count: 4)
            LazyVGrid(columns: columns, spacing: 16) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(width: 40, height: 40)
                        Image(AmityIcon.Chat.plusIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .frame(width: 18, height: 18)
                    }
                    Text(AmityLocalizedStringSet.Chat.AddGroupMember.memberChip.localizedString)
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColor)))
                        .lineLimit(1)
                }
                .onTapGesture {
                    let addPage = AmitySelectGroupMemberPage(
                        preselectedUsers: selectedUsers,
                        onMembersSelected: { updatedUsers in
                            selectedUsers = updatedUsers
                        }
                    )
                    let vc: UIViewController = AmitySwiftUIHostingController(rootView: addPage)
                    host.controller?.navigationController?.pushViewController(vc, animated: true)
                }

                currentUserCell

                ForEach(selectedUsers, id: \.userId) { user in
                    let avatarURL: URL? = {
                        guard let urlStr = user.getAvatarInfo()?.fileURL else { return nil }
                        return URL(string: urlStr)
                    }()
                    removableMemberCell(
                        displayName: user.displayName ?? user.userId,
                        avatarURL: avatarURL,
                        user: user
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var currentUserCell: some View {
        let currentUser = AmityUIKit4Manager.client.user?.snapshot
        let displayName = currentUser?.displayName ?? AmityUIKit4Manager.client.currentUserId ?? ""
        let avatarURL: URL? = {
            guard let urlStr = currentUser?.getAvatarInfo()?.fileURL else { return nil }
            return URL(string: urlStr)
        }()

        return VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                AmityUserProfileImageView(displayName: displayName, avatarURL: avatarURL)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                Color(viewConfig.theme.primaryColor.blend(.shade3))
                    .frame(width: 18, height: 18)
                    .clipShape(Circle())
                    .overlay(
                        Image(AmityIcon.moderatorBadgeIcon.getImageResource())
                            .resizable()
                            .scaledToFill()
                            .frame(width: 16, height: 16)
                    )
            }

            Text(AmityLocalizedStringSet.Chat.CreateGroup.memberYouLabel.localizedString)
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColor)))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }

    private func removableMemberCell(displayName: String, avatarURL: URL?, user: AmityUser) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                AmityUserProfileImageView(displayName: displayName, avatarURL: avatarURL)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                Button {
                    selectedUsers.removeAll { $0.userId == user.userId }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 18, height: 18)
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -1)
            }

            Text(displayName)
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColor)))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }

    // MARK: - Avatar pre-upload

    private func handleAvatarSelectionChange(_ newImage: UIImage?) {
        guard let image = newImage else {
            avatarUploadTask?.cancel()
            avatarUploadTask = nil
            uploadedAvatarImage = nil
            isUploadingAvatar = false
            return
        }
        if uploadedAvatarImage === image { return }
        avatarUploadTask?.cancel()
        uploadedAvatarImage = image
        isUploadingAvatar = true
        let task = Task<AmityImageData, Error> {
            try await FileRepositoryManager().uploadImage(image)
        }
        avatarUploadTask = task
        Task { @MainActor in
            do {
                _ = try await task.value
                guard uploadedAvatarImage === image else { return }
                isUploadingAvatar = false
            } catch {
                guard uploadedAvatarImage === image else { return }
                selectedAvatar = nil
                uploadedAvatarImage = nil
                avatarUploadTask = nil
                isUploadingAvatar = false
                activeAlert = error.isInappropriateImageUpload ? .inappropriateImage : .avatarUploadFailed
            }
        }
    }

    // MARK: - Create action

    private func createGroup() {
        isCreating = true
        errorMessage = nil

        Task { @MainActor in
            defer { isCreating = false }
            do {
                let channelManager = ChannelManager()
                let builder = AmityCommunityChannelCreateOptions()
                let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty {
                    builder.setDisplayName(trimmedName)
                } else {
                    let currentUser = AmityUIKit4Manager.client.user?.snapshot
                    var allUsers: [String] = []
                    if let name = currentUser?.displayName, !name.isEmpty {
                        allUsers.append(name)
                    } else if let userId = AmityUIKit4Manager.client.currentUserId {
                        allUsers.append(userId)
                    }
                    for user in selectedUsers {
                        guard user.userId != AmityUIKit4Manager.client.currentUserId else { continue }
                        allUsers.append(user.displayName ?? user.userId)
                    }
                    let generated = generateDisplayName(from: allUsers, maxLength: 100)
                    if !generated.isEmpty {
                        builder.setDisplayName(generated)
                    }
                }
                builder.setUserIds(selectedUsers.map { $0.userId })
                builder.setIsChannelPublic(isPublic)
                let channel = try await channelManager.createChannel(with: builder)

                if selectedAvatar != nil {
                    do {
                        let imageData: AmityImageData
                        if let task = avatarUploadTask {
                            do {
                                imageData = try await task.value
                            } catch {
                                let fileManager = FileRepositoryManager()
                                imageData = try await fileManager.uploadImage(selectedAvatar!)
                            }
                        } else if let avatar = selectedAvatar {
                            let fileManager = FileRepositoryManager()
                            imageData = try await fileManager.uploadImage(avatar)
                        } else {
                            return
                        }
                        let update = AmityChannelUpdateOptions(channelId: channel.channelId)
                        update.setAvatar(imageData)
                        try await channelManager.editChannel(with: update)
                    } catch {
                        if error.isInappropriateImageUpload {
                            activeAlert = .inappropriateImage
                        } else {
                            activeAlert = .avatarUploadFailed
                        }
                        return
                    }
                }

                let chatPage = AmityGroupChatPage(channelId: channel.channelId)
                let chatVC: UIViewController = AmitySwiftUIHostingController(rootView: chatPage)

                let internalNav = host.controller?.navigationController
                let tabBar = internalNav?.presentingViewController as? UITabBarController
                let appNav: UINavigationController? =
                    tabBar?.selectedViewController as? UINavigationController
                    ?? internalNav?.presentingViewController?.navigationController
                    ?? (internalNav?.presentingViewController as? UINavigationController)

                if let nav = appNav {
                    internalNav?.dismiss(animated: true) {
                        nav.pushViewController(chatVC, animated: true)
                    }
                } else {
                    chatVC.modalPresentationStyle = .fullScreen
                    internalNav?.dismiss(animated: true) {
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                            var top = root
                            while let presented = top.presentedViewController { top = presented }
                            top.present(chatVC, animated: true)
                        }
                    }
                }
            } catch {
                errorMessage = AmityLocalizedStringSet.Chat.CreateGroup.createError.localized(arguments: error.localizedDescription)
            }
        }
    }

    private func generateDisplayName(from names: [String], maxLength: Int) -> String {
        var result = ""
        for name in names {
            if result.isEmpty {
                if name.count <= maxLength {
                    result = name
                } else {
                    result = String(name.prefix(maxLength))
                    break
                }
            } else {
                let separator = ", "
                let needed = result.count + separator.count + name.count
                if needed <= maxLength {
                    result += separator + name
                } else {
                    let remaining = maxLength - result.count - separator.count
                    if remaining > 0 {
                        result += separator + String(name.prefix(remaining))
                    }
                    break
                }
            }
        }
        return result
    }
}
