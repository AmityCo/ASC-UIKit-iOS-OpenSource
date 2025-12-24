//
//  AmityNavigationBar.swift
//  AmityUIKit4
//
//  Created by Nishan on 9/9/2567 BE.
//

import SwiftUI

struct AmityNavigationBar: View {
    
    // Inherited from parent
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let title: String
    let isBackButtonEnabled: Bool
    let titleView: AnyView?
    let trailingView: AnyView?
    let leadingView: AnyView?
    let showDivider: Bool
    let isTransparent: Bool
    let tintColor: UIColor?
    
    /// Navigation Bar with title at center
    init(title: String) {
        self.title = title
        self.trailingView = nil
        self.leadingView = nil
        self.isBackButtonEnabled = false
        self.showDivider = false
        self.isTransparent = false
        self.tintColor = nil
        self.titleView = nil
    }
    
    /// Navigation Bar with back button & divider customization
    init(title: String, showBackButton: Bool, showDivider: Bool = false, isTransparent: Bool = false, tintColor: UIColor? = nil) {
        self.title = title
        self.isBackButtonEnabled = showBackButton
        self.leadingView = nil
        self.trailingView = nil
        self.showDivider = showDivider
        self.isTransparent = isTransparent
        self.tintColor = tintColor
        self.titleView = nil
    }
    
    /// Navigation Bar with title, leading view & empty trailing view customization
    init<LeadingView: View>(title: String, showDivider: Bool = false, isTransparent: Bool = false, tintColor: UIColor? = nil, @ViewBuilder leading: () -> LeadingView) {
        self.title = title
        self.isBackButtonEnabled = false
        self.showDivider = showDivider
        self.leadingView = AnyView(leading())
        self.trailingView = nil
        self.isTransparent = isTransparent
        self.tintColor = tintColor
        self.titleView = nil
    }
    
    /// Navigation Bar with title, back button, divider & trailing view customization
    init<TrailingView: View>(title: String, showBackButton: Bool, showDivider: Bool = false, isTransparent: Bool = false, @ViewBuilder trailing: () -> TrailingView) {
        self.title = title
        self.isBackButtonEnabled = showBackButton
        self.showDivider = showDivider
        self.leadingView = nil
        self.trailingView = AnyView(trailing())
        self.isTransparent = isTransparent
        self.tintColor = nil
        self.titleView = nil
    }
    
    /// Navigation Bar with title, divider, leading & trailing view customization
    init<LeadingView: View, TrailingView: View>(title: String, showDivider: Bool = false, isTransparent: Bool = false,  @ViewBuilder leading: () -> LeadingView, @ViewBuilder trailing: () -> TrailingView) {
        self.title = title
        self.showDivider = showDivider
        self.leadingView = AnyView(leading())
        self.trailingView = AnyView(trailing())
        self.isBackButtonEnabled = false
        self.isTransparent = isTransparent
        self.tintColor = nil
        self.titleView = nil
    }
    
    /// Navigation Bar with title, divider, leading & trailing view customization
    init<TitleView: View, LeadingView: View, TrailingView: View>(
        @ViewBuilder titleView: () -> TitleView,
        @ViewBuilder leading: () -> LeadingView,
        @ViewBuilder trailing: () -> TrailingView,
        showDivider: Bool = false,
        isTransparent: Bool = false
    ) {
        self.title = ""
        self.showDivider = showDivider
        self.leadingView = AnyView(leading())
        self.trailingView = AnyView(trailing())
        self.isBackButtonEnabled = false
        self.isTransparent = isTransparent
        self.tintColor = nil
        self.titleView = AnyView(titleView())
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack {
                    if let leadingView {
                        leadingView
                            .padding(.leading, 8)
                    } else if isBackButtonEnabled  {
                        BackButton(tintColor: tintColor)
                            .padding(.leading, 8)
                    }
                    
                    Spacer()
                }
                .layoutPriority(1)
                .frame(maxWidth: .infinity)

                if let titleView {
                    titleView
                        .padding(.horizontal, 8)
                        .lineLimit(1)
                        .layoutPriority(2)
                } else {
                    Text(title)
                        .applyTextStyle(.titleBold(Color(tintColor ?? viewConfig.theme.baseColor)))
                        .padding(.horizontal, 8)
                        .lineLimit(1)
                        .layoutPriority(2)
                }

                HStack {
                    Spacer()
                    
                    if let trailingView {
                        trailingView
                            .padding(.trailing, 12)
                    }
                }
                .layoutPriority(1)
                .frame(maxWidth: .infinity)
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .frame(minHeight: host.controller?.navigationController?.navigationBar.frame.height ?? 44)
            .background(isTransparent ? Color.clear : Color(viewConfig.theme.backgroundColor))
            
            if showDivider {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
                    .padding(.horizontal, -16)
            }
        }
    }
    
    struct BackButton: View {
        
        @EnvironmentObject var host: AmitySwiftUIHostWrapper
        @EnvironmentObject var viewConfig: AmityViewConfigController
        
        let tintColor: UIColor?
        var action: (() -> Void)?
        
        init(tintColor: UIColor? = nil, action: (() -> Void)? = nil) {
            self.action = action
            self.tintColor = tintColor
        }
        
        var body: some View {
            let backIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .backButtonElement, key: "icon", of: String.self) ?? "backIcon")
            Image(backIcon)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(tintColor ?? viewConfig.theme.baseColor))
                .frame(width: 24, height: 20)
                .padding(.vertical, 8)
                .onTapGesture {
                    if let action {
                        action()
                    } else {
                        host.controller?.navigationController?.popViewController(animated: true)
                    }
                }
                .isHidden(viewConfig.isHidden(elementId: .backButtonElement))
        }
    }
}

#if DEBUG
#Preview {
    ZStack(alignment: .top) {
        Color.green.opacity(0.1)
        
        VStack {
            AmityNavigationBar(title: "My Page")
            
            AmityNavigationBar(title: "My Page", showBackButton: true)
            
            AmityNavigationBar(title: "My Page", showBackButton: true) {
                HStack {
                    Image(systemName: "leaf.fill")
                    
                    Image(systemName: "cloud.fill")
                }
            }
            
            AmityNavigationBar(title: "My Page") {
                Image(systemName: "leaf.fill")
                    .padding(6)
            } trailing: {
                HStack {
                    Image(systemName: "leaf.fill")
                    
                    Image(systemName: "cloud.fill")
                }
            }
        }
    }
    .environmentObject(AmityViewConfigController(pageId: .socialHomePage))
}
#endif
