//
//  AmityGlobalBannedPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/12/25.
//

import SwiftUI
import Combine
import AmitySDK

struct AmityGlobalBannedPage: View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController = AmityViewConfigController(pageId: .socialHomePage)
    
    var body: some View {
        VStack(spacing: 0) {
            AmityNavigationBar(title: "Community", showBackButton: false, showDivider: true)
            
            Spacer()
            
            VStack(spacing: 12) {
                Image(AmityIcon.triangleErrorIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .frame(width: 56, height: 42)
                
                Text("You’ve been banned.")
                    .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))
                    .multilineTextAlignment(.center)
                
                Text("Based on your previous activities, you account has been banned from all feeds.")
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade1)))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
                
                Button {
                    host.controller?.dismissOrPop()
                } label: {
                    Text(AmityLocalizedStringSet.Social.livestreamBannedOkButton.localizedString)
                        .applyTextStyle(.bodyBold(.white))
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(height: 40)
                .background(Color(viewConfig.theme.primaryColor))
                .cornerRadius(8, corners: .allCorners)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
}

class AmityGlobalBannedViewModel: ObservableObject, AmityClientDelegate {
    
    
    @Published var isUserGlobalBanned: Bool = false
    @Published var isUserDeleted: Bool = false
    
    static let shared = AmityGlobalBannedViewModel()
    
    private var cancellable: Set<AnyCancellable> = []
    
    private init() {
        AmityUIKitManagerInternal.shared.client.delegate = self
    }
    
    func didReceiveError(error: any Error) {
        if error.isAmityErrorCode(.globalBan) {
            isUserGlobalBanned = true
            showGlobalBannedPage()
        }
        
        if error.isAmityErrorCode(.unauthorized) {
            isUserDeleted = true
            showErrorStatePage()
        }
    }
    
    
    private func showGlobalBannedPage() {
        UIApplication.rewind(to: AmitySwiftUIHostingController<AmitySocialHomePage>.self) { vc in
            let navController = vc?.navigationController
            
            let vc = AmitySwiftUIHostingController(rootView: AmityGlobalBannedPage())
            vc.modalPresentationStyle = .fullScreen
            navController?.present(vc, animated: false)
        }
       
    }
    
    private func showErrorStatePage() {
        UIApplication.rewind(to: AmitySwiftUIHostingController<AmitySocialHomePage>.self) { vc in
            let navController = vc?.navigationController
            
            let vc = AmitySwiftUIHostingController(rootView: AmityErrorStatePage())
            vc.modalPresentationStyle = .fullScreen
            navController?.present(vc, animated: false)
        }
    }
}
