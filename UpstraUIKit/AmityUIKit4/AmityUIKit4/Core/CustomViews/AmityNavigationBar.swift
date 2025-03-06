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
    let trailingView: AnyView?
    let leadingView: AnyView?
    let showDivider: Bool
        
    init(title: String) {
        self.title = title
        self.trailingView = nil
        self.leadingView = nil
        self.isBackButtonEnabled = false
        self.showDivider = false
    }
    
    init(title: String, showBackButton: Bool, showDivider: Bool = false) {
        self.title = title
        self.isBackButtonEnabled = showBackButton
        self.leadingView = nil
        self.trailingView = nil
        self.showDivider = showDivider
    }
    
    init<TrailingView: View>(title: String, showBackButton: Bool, showDivider: Bool = false, @ViewBuilder trailing: () -> TrailingView) {
        self.title = title
        self.isBackButtonEnabled = showBackButton
        self.showDivider = showDivider
        self.leadingView = nil
        self.trailingView = AnyView(trailing())
    }
    
    init<LeadingView: View, TrailingView: View>(title: String, showDivider: Bool = false, @ViewBuilder leading: () -> LeadingView, @ViewBuilder trailing: () -> TrailingView) {
        self.title = title
        self.showDivider = showDivider
        self.leadingView = AnyView(leading())
        self.trailingView = AnyView(trailing())
        self.isBackButtonEnabled = false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack {
                    if let leadingView {
                        leadingView
                            .padding(.leading, 8)
                    } else if isBackButtonEnabled  {
                        BackButton()
                            .padding(.leading, 8)
                    }
                    
                    Spacer()
                }
                .layoutPriority(1)
                .frame(maxWidth: .infinity)

                Text(title)
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                    .padding(.horizontal, 8)
                    .lineLimit(1)
                    .layoutPriority(2)

                HStack {
                    
                    if let trailingView {
                        Spacer()
                        
                        trailingView
                            .padding(.trailing, 16)
                    } else {
                        Spacer(minLength: 24)
                    }
                }
                .layoutPriority(1)
                .frame(maxWidth: .infinity)
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .frame(minHeight: host.controller?.navigationController?.navigationBar.frame.height ?? 44)
            .background(Color(viewConfig.theme.backgroundColor))
            
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
        
        var body: some View {
            let backIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .backButtonElement, key: "icon", of: String.self) ?? "backIcon")
            Image(backIcon)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .frame(width: 24, height: 20)
                .onTapGesture {
                    host.controller?.navigationController?.popViewController(animated: true)
                }
                .isHidden(viewConfig.isHidden(elementId: .backButtonElement))
                .padding(.vertical, 8)
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
