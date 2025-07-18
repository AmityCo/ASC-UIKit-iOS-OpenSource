//
//  AmityContentReportInputPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 25/4/25.
//

import SwiftUI

struct AmityContentReportInputPage: View {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @State private var textViewModel = InfoTextFieldModel(title: AmityLocalizedStringSet.Social.reportReasonOthersInputTitle.localizedString, placeholder: AmityLocalizedStringSet.Social.reportReasonOthersInputPlaceholder.localizedString, isMandatory: false, showOptionalTitle: true, infoMessage: nil, errorMessage: nil, isExpandable: true, maxCharCount: 300)
    @State private var text: String = ""
    @State private var isTextValid = true
    
    @ObservedObject var viewModel: AmityContentReportPageViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            HStack {
                Spacer()
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                
                Spacer()
            }
            
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    AmityNavigationBar(title: AmityLocalizedStringSet.Social.reportReasonOthersPageTitle.localizedString, showBackButton: true, showDivider: true) {
                        Image(AmityIcon.closeIcon.imageResource)
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .frame(width: 24, height: 20)
                            .padding(.vertical, 8)
                            .onTapGesture {
                                self.host.controller?.dismiss(animated: true)
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        InfoTextField(data: $textViewModel, text: $text, isValid: $isTextValid)
                            .alertColor(viewConfig.theme.alertColor)
                            .dividerColor(viewConfig.theme.baseColorShade4)
                            .titleTextColor(viewConfig.theme.baseColor)
                            .infoTextColor(viewConfig.theme.baseColorShade2)
                            .textFieldTextColor(viewConfig.theme.baseColorShade2)
                            .padding(.top, 24)
                            .padding([.horizontal, .bottom], 16)
                        
                        Spacer()
                        
                        Divider()
                        
                        Button(AmityLocalizedStringSet.Social.reportPageSubmitButton.localizedString) {
                            Task { @MainActor in
                                try await viewModel.flagContent(reason: .others(text))
                                
                                if viewModel.submissionState == .success {
                                    self.host.controller?.dismiss(animated: true)
                                    
                                    let toastMessage = AmityLocalizedStringSet.Social.reportReasonSuccessToastMessage.localized(arguments: viewModel.type.description.capitalized)
                                    Toast.showToast(style: .success, message: toastMessage)
                                }
                            }
                        }
                        .buttonStyle(AmityPrimaryButtonStyle(viewConfig: viewConfig))
                        .disabled(viewModel.submissionState == .submitting)
                        .padding(16)
                    }
                    .onTapGesture {
                        hideKeyboard()
                    }
                }
                
                ContentReportErrorView(action: {
                    self.host.controller?.dismiss(animated: true)
                }).visibleWhen(viewModel.submissionState == .contentError)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
    }
}
