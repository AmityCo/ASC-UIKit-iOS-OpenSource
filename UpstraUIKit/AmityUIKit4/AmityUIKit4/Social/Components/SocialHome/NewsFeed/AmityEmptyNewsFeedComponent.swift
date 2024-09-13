//
//  AmityEmptyNewsFeedComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/2/24.
//

import SwiftUI

public struct AmityEmptyNewsFeedComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    public var pageId: PageId?
    
    public var id: ComponentId {
        .emptyNewsFeedComponent
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    
    public init(pageId: PageId? = nil) {
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .emptyNewsFeedComponent))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            let emptyNewsfeedIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .illustration, key: "icon", of: String.self) ?? "")
            Image(emptyNewsfeedIcon)
                .resizable()
                .frame(size: CGSize(width: UIScreen.main.bounds.size.height / 4, height: UIScreen.main.bounds.size.height / 4))
                .isHidden(viewConfig.isHidden(elementId: .illustration))
            
            let title = viewConfig.getConfig(elementId: .title, key: "text", of: String.self) ?? ""
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                .isHidden(viewConfig.isHidden(elementId: .title))
            
            let description = viewConfig.getConfig(elementId: .description, key: "text", of: String.self) ?? ""
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                .padding(.top, 4)
                .isHidden(viewConfig.isHidden(elementId: .description))
            
            let exploreCommunityButtonIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .exploreCommunittiesButton, key: "icon", of: String.self) ?? "")
            let exploreCommunityButtonText = viewConfig.getConfig(elementId: .exploreCommunittiesButton, key: "text", of: String.self) ?? ""
            HStack(alignment: .center, spacing: 8) {
                Image(exploreCommunityButtonIcon)
                    .resizable()
                    .frame(size: CGSize(width: 20.0, height: 20.0))
                    .padding(.leading, 24)
                    
                Text(exploreCommunityButtonText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.backgroundColor))
                    .padding([.top, .bottom], 12)
                    .padding(.trailing, 24)
            }
            .background(Color(viewConfig.theme.primaryColor))
            .clipShape(RoundedRectangle(cornerRadius: 5.0))
            .padding(.top, 17)
            .onTapGesture {
                Log.add(event: .info, "Explore Community")
            }
            .isHidden(viewConfig.isHidden(elementId: .exploreCommunittiesButton))
            
            let createCommunityButtonText = viewConfig.getConfig(elementId: .createCommunityButton, key: "text", of: String.self) ?? ""
            Text(createCommunityButtonText)
                .font(.system(size: 15))
                .foregroundColor(Color(viewConfig.theme.primaryColor))
                .padding(.top, 14)
                .onTapGesture {
                    let page = AmityCommunitySetupPage(mode: .create)
                    let vc = AmitySwiftUIHostingController(rootView: page)
                    host.controller?.navigationController?.pushViewController(vc, animation: .presentation)
                }
                .isHidden(viewConfig.isHidden(elementId: .createCommunityButton))
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .frame(maxHeight: .infinity)
        .updateTheme(with: viewConfig)
    }
}


#if DEBUG
#Preview {
    AmityEmptyNewsFeedComponent()
}
#endif
