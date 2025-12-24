//
//  ContentReportPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 25/4/25.
//

import SwiftUI
import AmitySDK

// Internal Page
struct AmityContentReportPage: View {
        
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @StateObject private var viewModel: AmityContentReportPageViewModel
    @State private var reasons: [AmityContentFlagReason] = [
        .communityGuidelines,
        .harassmentOrBullying,
        .selfHarmOrSuicide,
        .violenceOrThreateningContent,
        .sellingRestrictedItems,
        .sexualContentOrNudity,
        .spamOrScams,
        .falseInformation
    ]
        
    init(type: ContentReportType) {
        self._viewModel = StateObject(wrappedValue: AmityContentReportPageViewModel(type: type))
    }
    
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
                    AmityNavigationBar(title: AmityLocalizedStringSet.Social.reportReasonPageTitle.localizedString, showBackButton: false, showDivider: true) {
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
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            
                            Text(AmityLocalizedStringSet.Social.reportPageInfoLabel.localizedString)
                                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                                .padding(.vertical, 12)
                            
                            ForEach(reasons, id: \.description) { item in
                                OptionButton(title: item.description, isSelected: viewModel.selectedReason?.isEqual(item: item) ?? false) {
                                    viewModel.selectedReason = item
                                }
                            }
                            
                            Button(action: {
                                let inputPage = AmityContentReportInputPage(viewModel: viewModel)
                                    .updateTheme(with: viewConfig)
                                let vc = AmitySwiftUIHostingController(rootView: inputPage)
                                self.host.controller?.navigationController?.pushViewController(vc, animated: true)
                            }, label: {
                                HStack {
                                    let otherReason = AmityContentFlagReason.others("")
                                    Text(otherReason.description)
                                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(Color(viewConfig.theme.baseColor))
                                        .padding(.trailing, 2)
                                }
                                .contentShape(Rectangle())
                            })
                            .buttonStyle(.plain)
                            .padding(.vertical, 16)
                            
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Divider()
                    
                    Button(AmityLocalizedStringSet.Social.reportPageSubmitButton.localizedString) {
                        guard let reason = viewModel.selectedReason else { return }
                        
                        Task { @MainActor in
                            try await viewModel.flagContent(reason: reason)
                            
                            if viewModel.submissionState == .success {
                                self.host.controller?.dismiss(animated: true)
                                
                                let toastMessage = AmityLocalizedStringSet.Social.reportReasonSuccessToastMessage.localized(arguments: viewModel.type.description.capitalized)
                                Toast.showToast(style: .success, message: toastMessage)
                            }
                        }
                        
                    }
                    .buttonStyle(AmityPrimaryButtonStyle(viewConfig: viewConfig, backgroundColor: viewConfig.theme.primaryColor))
                    .disabled(viewModel.selectedReason == nil || viewModel.submissionState == .submitting)
                    .padding(16)
                }
                
                ContentReportErrorView(action: {
                    self.host.controller?.dismiss(animated: true)
                })
                .visibleWhen(viewModel.submissionState == .contentError)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
    }
}

extension AmityContentFlagReason {
    
    func isEqual(item: AmityContentFlagReason) -> Bool {
        return self.description == item.description
    }
}
