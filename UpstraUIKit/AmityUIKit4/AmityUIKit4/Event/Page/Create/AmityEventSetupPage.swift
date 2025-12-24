//
//  AmityEventSetupPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 10/10/25.
//

import SwiftUI
import AVKit
import AmitySDK

public struct AmityEventSetupPage: AmityPageView {
    
    public var id: PageId {
        return .eventSetupPage
    }
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var sheetHandler = EventSetupPageSheetHandler()
    @StateObject private var draft: EventDraft  // Draft contains all information inputted by user in this setup page
    @StateObject private var viewModel: AmityEventSetupPageViewModel
    
    // Avatar
    @StateObject private var imagePickerViewModel = ImageVideoPickerViewModel()
    @State private var showImagePickerOptions: Bool = false
    @State private var showImagePicker: (isShown: Bool, mediaType: [UTType], sourceType: UIImagePickerController.SourceType) = (
        false, [UTType.image], .photoLibrary
    )
    
    @State private var isSubmitting = false
    
    /// Community Name data
    @State private var nameTextFieldModel: InfoTextFieldModel = InfoTextFieldModel(
        title: AmityLocalizedStringSet.Social.eventSetupEventNameTitle.localizedString,
        placeholder: AmityLocalizedStringSet.Social.eventSetupEventNamePlaceholder.localizedString,
        isMandatory: false,
        isExpandable: true,
        maxCharCount: 60,
        allowNewLine: false
    )
    @State private var isTextValid: Bool = true
    
    /// About data
    @State private var aboutTextFieldModel: InfoTextFieldModel = InfoTextFieldModel(
        title: AmityLocalizedStringSet.Social.eventSetupEventDetailsTitle.localizedString,
        placeholder: AmityLocalizedStringSet.Social.eventSetupEventDetailsPlaceholder.localizedString,
        isMandatory: false,
        showOptionalTitle: false,
        isExpandable: true,
        expandedLineLimit: 100,
        maxCharCount: 1000
    )
    
    @State private var isAboutValid: Bool = true
    @State private var isEndDateOptionRemoved = false
    @State private var showDismissAlert = false
    @State private var isInputValid: Bool = false
    
    private let mode: AmityEventSetupPageMode
    private let isInCreateMode: Bool
    
    public init(mode: AmityEventSetupPageMode) {
        self.mode = mode
        self._viewConfig = StateObject(
            wrappedValue: AmityViewConfigController(pageId: .eventSetupPage))
        
        switch mode {
        case .create:
            self._draft = StateObject(wrappedValue: EventDraft())
            self._viewModel = StateObject(wrappedValue: AmityEventSetupPageViewModel(event: nil))
            self.isInCreateMode = true
        case .edit(let event):
            self._draft = StateObject(wrappedValue: EventDraft(event: event))
            self._viewModel = StateObject(wrappedValue: AmityEventSetupPageViewModel(event: event))
            self.isInCreateMode = false
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AmityNavigationBar(titleView: {
                switch mode {
                case .create:
                    VStack(spacing: 4) {
                        Text(AmityLocalizedStringSet.Social.eventSetupCreateEventTitle.localizedString)
                            .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                        
                        Text(mode.pageTitle)
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    }
                    .padding(.bottom, 12)
                case .edit:
                    Text(AmityLocalizedStringSet.Social.eventSetupEditEventTitle.localizedString)
                        .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                }
            }, leading: {
                switch mode {
                case .create:
                    Button {
                        handleScreenDismissal()
                    } label: {
                        Image(AmityIcon.closeIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .frame(width: 24, height: 24)
                    }
                case .edit:
                    AmityNavigationBar.BackButton(action: {
                        handleScreenDismissal()
                    })
                }
            }, trailing: {
                EmptyView()
            }, showDivider: false, isTransparent: false)
            .alert(isPresented: $showDismissAlert) {
                Alert(title: Text(AmityLocalizedStringSet.Social.eventSetupLeaveAlertTitle.localizedString), message: Text( isInCreateMode ? AmityLocalizedStringSet.Social.eventSetupLeaveAlertMessage.localizedString : AmityLocalizedStringSet.Social.eventDetailAlertLeaveWithoutFinishingMessage.localizedString), primaryButton: .cancel(Text(AmityLocalizedStringSet.General.cancel.localizedString)), secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.leave.localizedString), action: {
                    
                    dismissScreen()
                }))
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Color.black.opacity(0.5)
                        .overlay(
                            ZStack {
                                if case .edit = mode {
                                    AsyncImage(placeholder: AmityIcon.eventImagePlaceholder.imageResource, url: URL(string: draft.avatarUrl ?? ""), contentMode: .fill)
                                }
                                
                                if let image = imagePickerViewModel.selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .clipped()
                                }
                                
                                Color.black
                                    .opacity(0.25)
                                
                                Image(AmityIcon.cameraAttatchmentIcon.imageResource)
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 32, height: 28)
                                    .foregroundColor(Color.white)
                            }
                        )
                        .clipped()
                        .frame(height: 210)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            hideKeyboard()
                            
                            showImagePickerOptions.toggle()
                        }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        infoSection
                        
                        dateAndTimeSection
                        
                        Divider()
                        
                        locationSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            
            footerSection
            
        }
        .onChange(of: imagePickerViewModel.selectedImage, perform: { newValue in
            draft.avatar = newValue
            draft.isAvatarChanged = true
        })
        .bottomSheet(isShowing: $showImagePickerOptions, height: .contentSize) {
            VStack(spacing: 0) {
                BottomSheetItemView(icon: AmityIcon.cameraAttatchmentIcon.imageResource, text: AmityLocalizedStringSet.Social.eventSetupCamera.localizedString, iconBackground: .circular)
                    .onTapGesture {
                        /// Delay opening picker view a bit to avoid conflicts of opening & closing fullScreenCover views
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            showImagePicker.sourceType = .camera
                            showImagePicker.isShown = true
                        }
                        
                        showImagePickerOptions.toggle()
                    }
                
                BottomSheetItemView(icon: AmityIcon.photoAttatchmentIcon.imageResource, text: AmityLocalizedStringSet.Social.eventSetupPhoto.localizedString, iconBackground: .circular)
                    .onTapGesture {
                        /// Delay opening picker view a bit to avoid conflicts of opening & closing fullScreenCover views
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            showImagePicker.sourceType = .photoLibrary
                            showImagePicker.isShown = true
                        }
                        
                        showImagePickerOptions.toggle()
                    }
            }
            .padding(.bottom, 64)
        }
        .fullScreenCover(isPresented: $showImagePicker.isShown) {
            ImageVideoCameraPicker(
                viewModel: imagePickerViewModel, mediaType: $showImagePicker.mediaType,
                sourceType: $showImagePicker.sourceType
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $sheetHandler.isSheetEnabled, content: {
            sheetHandler.getDestination()
        })
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    @ViewBuilder
    var infoSection: some View {
        // Event Name
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
        .onChange(of: draft.name, perform: { newValue in
            
            validateEventInputs()
        })
        
        // Event Description
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
        .onChange(of: draft.about, perform: { newValue in
            validateEventInputs()
        })
    }
    
    @ViewBuilder
    var dateAndTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AmityLocalizedStringSet.Social.eventSetupDateAndTime.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
            
            Text(AmityLocalizedStringSet.Social.eventSetupTimezone.localizedString)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                .padding(.top, 20)
            
            Button(TimeZoneFormatter.string(from: draft.timezone)) {
                hideKeyboard()
                
                sheetHandler.showSheet(for: .timezone(onSelection: { timezone in
                    draft.timezone = timezone
                }))
            }.buttonStyle(AmityDropDownButtonStyle(viewConfig: viewConfig))
                .lineLimit(1)
            
            Text(AmityLocalizedStringSet.Social.eventSetupStartsOn.localizedString)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                .padding(.top, 8)
            
            Button(Formatters.eventDurationFormatter.string(from: draft.startDate)) {
                hideKeyboard()
                
                sheetHandler.showSheet(for: .startDate(current: draft.startDate, onSelection: { date in
                    draft.startDate = date
                    
                    // If start date is modified and is greater than end date, we change the value for end date
                    if draft.hasEndDate, draft.endDate <= draft.startDate {
                        let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: date)
                        draft.endDate = endTime ?? date
                    }
                    
                    validateEventInputs()
                }))
            }.buttonStyle(AmitySelectionButtonStyle(viewConfig: viewConfig, alignment: .leading))
            
            if isEndDateOptionRemoved {
                Text(AmityLocalizedStringSet.Social.eventSetupNoEndTimeInfo.localizedString)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    .padding(.top, -4)
                
                Button(AmityLocalizedStringSet.Social.eventSetupAddEndDateTime.localizedString) {
                    isEndDateOptionRemoved = false
                    draft.hasEndDate = true
                    draft.endDate = draft.setupEndTime()
                    
                    validateEventInputs()
                }
                .buttonStyle(AmityLineButtonStyle(viewConfig: viewConfig))
                .padding(.top, 8)
            } else {
                Text(AmityLocalizedStringSet.Social.eventSetupEndsOn.localizedString)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                    .padding(.top, 8)
                
                HStack {
                    Button(Formatters.eventDurationFormatter.string(from: draft.endDate)) {
                        hideKeyboard()
                        
                        let startDate = Calendar.current.date(byAdding: .hour, value: 1, to: draft.startDate) ?? draft.startDate
                        sheetHandler.showSheet(for: .endDate(current: draft.endDate, startDate: startDate, onSelection: { date in
                            draft.endDate = date
                            
                            validateEventInputs()
                        }))
                    }.buttonStyle(AmitySelectionButtonStyle(viewConfig: viewConfig, alignment: .leading))
                    
                    Button(action: {
                        hideKeyboard()
                        
                        withAnimation {
                            isEndDateOptionRemoved = true
                            draft.hasEndDate = false
                        }
                        
                        validateEventInputs()
                    }, label: {
                        Image(AmityIcon.trashBinIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .padding(.horizontal, 8)
                    })
                }
            }
        }
    }
    
    @ViewBuilder
    var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AmityLocalizedStringSet.Social.eventSetupLocation.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
            
            Button(action: {
                hideKeyboard()
                
                sheetHandler.showSheet(for: .location(current: draft.location, onSelection: { location in
                    draft.location = location
                    
                    validateEventInputs()
                }))
            }, label: {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(draft.locationValue ?? AmityLocalizedStringSet.Social.eventSetupLocationPlaceholder.localizedString)
                            .applyTextStyle(.body(Color(draft.locationValue == nil ? viewConfig.theme.baseColorShade3 : viewConfig.theme.baseColor)))
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .renderingMode(.template)
                            .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    }
                    .padding(.bottom, 16)
                    .padding(.top, 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    
                    Divider()
                }
                .contentShape(Rectangle())
            })
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    var footerSection: some View {
        Rectangle()
            .fill(Color(viewConfig.theme.baseColorShade4))
            .frame(height: 1)
            .padding(.bottom, 16)
        
        Button {
            hideKeyboard()
            
            var isInCreateMode = false
            var communityId: String = ""
            
            switch mode {
            case .create(let targetId, _):
                isInCreateMode = true
                communityId = targetId
                
            case .edit(let event):
                isInCreateMode = false
                
                // we allow editing event < 15 minutes before start time
                let currentTime = Date()
                let eventEditThresholdTime = Calendar.current.date(byAdding: .minute, value: -15, to: event.startTime) ?? currentTime
                
                if currentTime > eventEditThresholdTime {
                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.eventSetupUpdateTimeLimitError.localizedString, bottomPadding: 70)
                    return
                }
            }
            
            guard draft.isEventStartTimeValid() else {
                let errorMessage = isInCreateMode ? AmityLocalizedStringSet.Social.eventSetupCreateTimeLimitError.localizedString : AmityLocalizedStringSet.Social.eventSetupUpdateTimeLimitErrorGeneric.localizedString
                Toast.showToast(style: .warning, message: errorMessage, bottomPadding: 70)
                return
            }
            
            isSubmitting = true
            
            // Start creation process
            let loadingMessage = isInCreateMode ? AmityLocalizedStringSet.Social.eventSetupCreating.localizedString : AmityLocalizedStringSet.Social.eventSetupSaving.localizedString
            Toast.showToast(style: .loading, message: loadingMessage, bottomPadding: 70)
            
            Task { @MainActor in
                do {
                    if isInCreateMode {
                        let event = try await viewModel.createEvent(draft: draft, targetId: communityId)
                        
                        Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.eventSetupSuccessfullyCreated.localizedString, bottomPadding: 70)
                        
                        AmityUIKit4Manager.behaviour.eventSetupPageBehavior?.goToEventDetailPage(context: .init(page: self, event: event))
                    } else {
                        try await viewModel.updateEvent(draft: draft)
                        
                        Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.eventSetupSuccessfullyUpdated.localizedString, bottomPadding: 70)
                        
                        dismissScreen()
                    }
                } catch {
                    
                    if error.isAmityErrorCode(.uploadFailed) {
                        self.showImageUploadFailAlert()
                    } else if error.isAmityErrorCode(.linkNotAllowed) {
                        let errorMessage = isInCreateMode ? AmityLocalizedStringSet.Social.eventSetupCreateLinkNotAllowedError.localizedString : AmityLocalizedStringSet.Social.eventSetupUpdateLinkNotAllowedError.localizedString
                        Toast.showToast(style: .warning, message: errorMessage, bottomPadding: 70)
                    } else if error.isAmityErrorCode(.banWordFound) {
                        let errorMessage = isInCreateMode ? AmityLocalizedStringSet.Social.eventSetupCreateBanWordError.localizedString : AmityLocalizedStringSet.Social.eventSetupUpdateBanWordError.localizedString
                        Toast.showToast(style: .warning, message: errorMessage, bottomPadding: 70)
                    } else {
                        let message = isInCreateMode ? AmityLocalizedStringSet.Social.eventSetupCreateFailed.localizedString : AmityLocalizedStringSet.Social.eventSetupUpdateFailed.localizedString
                        Toast.showToast(style: .warning, message: message, bottomPadding: 70)
                    }
                    
                    isSubmitting = false
                }
            }
        } label: {
            HStack {
                if isInCreateMode {
                    Image(AmityIcon.plusIcon.imageResource)
                        .renderingMode(.template)
                        .foregroundColor(.white)
                }
                
                Text(isInCreateMode ? AmityLocalizedStringSet.Social.eventSetupCreateButton.localizedString : AmityLocalizedStringSet.Social.eventSetupSaveButton.localizedString)
            }
        }
        .buttonStyle(AmityPrimaryButtonStyle(viewConfig: viewConfig))
        .disabled(!isInputValid || isSubmitting)
        .padding(.horizontal, 16)
        
        // Additional spacing at the bottom
        Rectangle()
            .fill(Color.clear)
            .frame(height: 16)
    }
    
    func validateEventInputs() {
        let isAboutValid = !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !draft.about.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isLocationValid = draft.location != nil
        let isDateTimeValid = draft.hasEndDate ? draft.endDate > draft.startDate : true
        
        isInputValid = isAboutValid && isLocationValid && isDateTimeValid
    }
    
    func showImageUploadFailAlert() {
        let alertController = UIAlertController(
            title: AmityLocalizedStringSet.Social.eventSetupUploadFailedTitle.localizedString, message: AmityLocalizedStringSet.Social.eventSetupUploadFailedMessage.localizedString, preferredStyle: .alert)
        let confirmAction = UIAlertAction(
            title: AmityLocalizedStringSet.General.okay.localizedString,
            style: .default) { action in
                
            }
        
        alertController.addAction(confirmAction)
        host.controller?.present(alertController, animated: true)
    }
    
    func handleScreenDismissal() {
        var draftToCompare: EventDraft
        
        switch mode {
        case .create:
            draftToCompare = EventDraft()
        case .edit(let event):
            draftToCompare = EventDraft(event: event)
        }
        
        if draft.hasChanges(with: draftToCompare) {
            showDismissAlert = true
        } else {
            dismissScreen()
        }
    }
    
    func dismissScreen(animated: Bool = true) {
        switch mode {
        case .create:
            host.controller?.navigationController?.dismiss(animated: animated)
        case .edit:
            host.controller?.navigationController?.popViewController(animated: animated)
        }
    }
}

open class AmityEventSetupPageBehavior {
    
    open class Context {
        
        let page: AmityEventSetupPage
        let event: AmityEvent?
        
        public init(page: AmityEventSetupPage, event: AmityEvent?) {
            self.page = page
            self.event = event
        }
    }
    
    public init() { }
    
    public func goToEventDetailPage(context: AmityEventSetupPageBehavior.Context) {
        guard let event = context.event else { return }
        let eventDetailPage = AmityEventDetailPage(event: event, context: .init(isNewEvent: true))
        let host = AmitySwiftUIHostingController(rootView: eventDetailPage)
        host.navigationController?.navigationBar.isHidden = true
        
        context.page.host.controller?.navigationController?.pushViewController(host)
    }
}
