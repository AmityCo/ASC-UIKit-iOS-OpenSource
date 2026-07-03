//
//  AmityEditGroupProfilePage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK
import PhotosUI

// MARK: - ViewModel

@MainActor
final class AmityEditGroupProfileViewModel: ObservableObject {
    @Published var displayName: String
    @Published var avatarURL: URL?
    @Published var selectedImage: UIImage?
    @Published var isSaving: Bool = false
    @Published var isUploadingAvatar: Bool = false
    @Published var pendingAvatarError: Error? = nil

    var hasChanged: Bool {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed != originalName || selectedImage != nil
    }

    private let channelId: String
    private let originalName: String
    private let channelManager = ChannelManager()
    private let fileManager = FileRepositoryManager()

    private var avatarUploadTask: Task<AmityImageData, Error>?
    private var avatarUploadImage: UIImage?

    init(channelId: String, displayName: String, avatarURL: URL?) {
        self.channelId = channelId
        self.originalName = displayName
        self.displayName = displayName
        self.avatarURL = avatarURL
    }

    func onAvatarSelectionChange(_ image: UIImage?) {
        guard let image else {
            avatarUploadTask?.cancel()
            avatarUploadTask = nil
            avatarUploadImage = nil
            isUploadingAvatar = false
            return
        }
        if avatarUploadImage === image { return }

        avatarUploadTask?.cancel()
        avatarUploadImage = image
        isUploadingAvatar = true
        pendingAvatarError = nil
        let task = Task<AmityImageData, Error> { [fileManager] in
            try await fileManager.uploadImage(image)
        }
        avatarUploadTask = task
        Task { @MainActor [weak self] in
            do {
                _ = try await task.value
                guard let self, self.avatarUploadImage === image else { return }
                self.isUploadingAvatar = false
            } catch {
                guard let self, self.avatarUploadImage === image else { return }
                self.selectedImage = nil
                self.avatarUploadImage = nil
                self.avatarUploadTask = nil
                self.isUploadingAvatar = false
                self.pendingAvatarError = error
            }
        }
    }

    func save() async throws {
        isSaving = true
        defer { isSaving = false }

        let builder = AmityChannelUpdateOptions(channelId: channelId)
        builder.setDisplayName(displayName.trimmingCharacters(in: .whitespacesAndNewlines))

        if selectedImage != nil {
            if let task = avatarUploadTask {
                do {
                    let imageData = try await task.value
                    builder.setAvatar(imageData)
                } catch {
                    if let image = selectedImage {
                        let imageData = try await fileManager.uploadImage(image)
                        builder.setAvatar(imageData)
                    }
                }
            } else if let image = selectedImage {
                let imageData = try await fileManager.uploadImage(image)
                builder.setAvatar(imageData)
            }
        }

        try await channelManager.editChannel(with: builder)
    }
}

// MARK: - Alert cases

private enum EditGroupProfileAlert: Identifiable {
    case inappropriateImage
    case uploadFailed

    var id: Self { self }
}

// MARK: - Page

public struct AmityEditGroupProfilePage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .editGroupProfilePage }

    @StateObject private var viewModel: AmityEditGroupProfileViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var showImagePicker = false
    @State private var showImageSourceSheet = false
    @State private var showCamera = false
    @State private var showCameraPicker = false
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var toastStyle: ToastStyle = .success
    @State private var activeAlert: EditGroupProfileAlert? = nil

    private let onSaved: (() -> Void)?

    public init(channelId: String, displayName: String, avatarURL: URL?, onSaved: (() -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: AmityEditGroupProfileViewModel(channelId: channelId, displayName: displayName, avatarURL: avatarURL))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .editGroupProfilePage))
        self.onSaved = onSaved
    }

    public var body: some View {
        VStack(spacing: 0) {
            navBar

            ScrollView {
                VStack(spacing: 0) {
                    // Avatar picker
                    avatarPicker
                        .padding(.top, 24)

                    Spacer().frame(height: 16)

                    // Name field
                    nameField
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .navigationBarHidden(true)
        .showToast(isPresented: $showToast, style: toastStyle, message: toastMessage, bottomPadding: 80)
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedImage: $viewModel.selectedImage)
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraPickerView(selectedImage: $viewModel.selectedImage)
        }
        .onChange(of: viewModel.selectedImage) { newImage in
            viewModel.onAvatarSelectionChange(newImage)
        }
        .onReceive(viewModel.$pendingAvatarError) { error in
            guard let error else { return }
            activeAlert = error.isInappropriateImageUpload ? .inappropriateImage : .uploadFailed
            viewModel.pendingAvatarError = nil
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
                        showImagePicker = true
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
            case .inappropriateImage:
                return Alert(
                    title: Text(AmityLocalizedStringSet.Chat.EditGroupProfile.uploadFailedTitle.localizedString),
                    message: Text(AmityLocalizedStringSet.Chat.EditGroupProfile.uploadFailedMessage.localizedString),
                    dismissButton: .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString))
                )
            case .uploadFailed:
                return Alert(
                    title: Text(AmityLocalizedStringSet.Chat.uploadFailedTitle.localizedString),
                    message: Text(AmityLocalizedStringSet.Chat.uploadFailedMessage.localizedString),
                    dismissButton: .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString))
                )
            }
        }
    }

    private var navBar: some View {
        ZStack {
            // Centered title
            Text(AmityLocalizedStringSet.Chat.EditGroupProfile.navbarTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .frame(maxWidth: .infinity)

            HStack {
                // Back button — left
                Button {
                    host.controller?.navigationController?.popViewController(animated: true)
                } label: {
                    Image(AmityIcon.Chat.backButtonIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 17, height: 17)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                Spacer()

                // Save button — right
                Button {
                    Task {
                        do {
                            try await viewModel.save()
                            toastStyle = .success
                            toastMessage = AmityLocalizedStringSet.Chat.EditGroupProfile.toastSuccess.localizedString
                            showToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                host.controller?.navigationController?.popViewController(animated: true)
                                onSaved?()
                            }
                        } catch {
                            if error.isInappropriateImageUpload {
                                activeAlert = .inappropriateImage
                            } else {
                                activeAlert = .uploadFailed
                            }
                        }
                    }
                } label: {
                    Text(AmityLocalizedStringSet.Chat.EditGroupProfile.save.localizedString)
                        .applyTextStyle(.bodyBold(
                            (viewModel.hasChanged && !viewModel.isUploadingAvatar)
                                ? Color(viewConfig.theme.primaryColor)
                                : Color(viewConfig.theme.primaryColor.blend(.shade2))))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasChanged || viewModel.isSaving || viewModel.isUploadingAvatar)
                .padding(.trailing, 4)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    private var avatarPicker: some View {
        Button {
            showImageSourceSheet = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(viewConfig.theme.primaryColor.blend(.shade2)))
                    .frame(width: 120, height: 120)

                if viewModel.selectedImage == nil && viewModel.avatarURL == nil {
                    Image(AmityIcon.Chat.groupAvatarPlaceholderIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }

                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                } else if let url = viewModel.avatarURL {
                    AsyncImage(placeholderView: {
                        Color(viewConfig.theme.primaryColor.blend(.shade2))
                    }, url: url)
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }

                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 120, height: 120)

                if viewModel.isUploadingAvatar {
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

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Text(AmityLocalizedStringSet.Chat.EditGroupProfile.nameLabel.localizedString)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    Text(AmityLocalizedStringSet.Chat.EditGroupProfile.nameRequired.localizedString)
                        .applyTextStyle(.custom(12, .regular, Color(viewConfig.theme.baseColorShade3)))
                }
                Spacer()
                Text("\(viewModel.displayName.count)/100")
                    .applyTextStyle(.custom(12, .regular, viewModel.displayName.count > 100
                                     ? Color.red
                                     : Color(viewConfig.theme.baseColorShade2)))
            }

            ZStack(alignment: .topLeading) {
                Text(viewModel.displayName.isEmpty ? " " : viewModel.displayName)
                    .applyTextStyle(.custom(16, .regular, .clear))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Placeholder
                if viewModel.displayName.isEmpty {
                    Text(AmityLocalizedStringSet.Chat.EditGroupProfile.namePlaceholder.localizedString)
                        .applyTextStyle(.custom(16, .regular, Color(viewConfig.theme.baseColorShade3)))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $viewModel.displayName)
                    .applyTextStyle(.custom(16, .regular, Color(viewConfig.theme.baseColor)))
                    .transparentBackground()
                    .background(Color.clear)
                    .onChange(of: viewModel.displayName) { newValue in
                        let limit = 100
                        if newValue.count > limit {
                            viewModel.displayName = String(newValue.prefix(limit))
                        }
                    }
            }
            .padding(.bottom, 4)
            .overlay(
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
    }
}

// MARK: - Camera Picker Wrapper

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let edited = info[.editedImage] as? UIImage {
                parent.selectedImage = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.selectedImage = original
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        init(_ parent: ImagePickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let edited = info[.editedImage] as? UIImage {
                parent.selectedImage = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.selectedImage = original
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
