//
//  AmityTopSearchBarComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/21/24.
//

import SwiftUI
import Combine

public struct AmityTopSearchBarComponent: AmityComponentView {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        .topSearchBarComponent
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @ObservedObject private var viewModel: AmityGlobalSearchViewModel
    
    public init(viewModel: AmityGlobalSearchViewModel, pageId: PageId? = nil) {
        self.viewModel = viewModel
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .topSearchBarComponent))
    }
    
   
    public var body: some View {
        HStack(spacing: 5) {
            HStack(spacing: 0) {
                let searchIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .searchIcon, key: "icon", of: String.self) ?? "")
                Image(searchIcon)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    .frame(width: 20, height: 20)
                    .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 8))
                    .isHidden(viewConfig.isHidden(elementId: .searchIcon), remove: true)
                    .accessibilityIdentifier(AccessibilityID.Social.TopSearchBar.searchIcon)
                    
                let placeholder = viewModel.searchType == .myCommunities ? "Search my community" : "Search community and user"
                TextField(placeholder, text: $viewModel.searchKeyword)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                
                if !viewModel.searchKeyword.isEmpty {
                    Button(action: {
                        viewModel.searchKeyword = ""
                    }, label: {
                        let clearIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .clearButton, key: "icon", of: String.self) ?? "")
                        Image(clearIcon)
                            .resizable()
                            .frame(width: 17, height: 17)
                            .padding(.trailing, 12)
                    })
                    .isHidden(viewConfig.isHidden(elementId: .clearButton))
                    .accessibilityIdentifier(AccessibilityID.Social.TopSearchBar.clearButton)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(viewConfig.theme.baseColorShade4))
            .clipShape(RoundedCorner(radius: 8))
            .padding(.leading, 10)
            
            
            Button(action: {
                host.controller?.dismiss(animated: false)
            }, label: {
                let cancelButtonTitle = viewConfig.getConfig(elementId: .cancelButtonElement, key: "text", of: String.self) ?? ""
                Text(cancelButtonTitle)
            })
            .padding(.trailing, 10)
            .isHidden(viewConfig.isHidden(elementId: .cancelButtonElement), remove: true)
        }
        .updateTheme(with: viewConfig)
        
    }
}
