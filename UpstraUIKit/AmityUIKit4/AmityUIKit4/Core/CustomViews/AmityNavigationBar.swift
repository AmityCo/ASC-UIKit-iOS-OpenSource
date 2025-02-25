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
        
    init(title: String) {
        self.title = title
        self.trailingView = nil
        self.leadingView = nil
        self.isBackButtonEnabled = false
    }
    
    init(title: String, showBackButton: Bool) {
        self.title = title
        self.isBackButtonEnabled = showBackButton
        self.leadingView = nil
        self.trailingView = nil
    }
    
    init<TrailingView: View>(title: String, showBackButton: Bool, @ViewBuilder trailing: () -> TrailingView) {
        self.title = title
        self.isBackButtonEnabled = showBackButton
        self.leadingView = nil
        self.trailingView = AnyView(trailing())
    }
    
    init<LeadingView: View, TrailingView: View>(title: String, @ViewBuilder leading: () -> LeadingView, @ViewBuilder trailing: () -> TrailingView) {
        self.title = title
        self.leadingView = AnyView(leading())
        self.trailingView = AnyView(trailing())
        self.isBackButtonEnabled = false
    }
    
    var body: some View {
        HStack(spacing: 0) {
            HStack {
                if let leadingView {
                    leadingView
                } else if isBackButtonEnabled  {
                    BackButton()
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
                Spacer()
                
                if let trailingView {
                    trailingView
                }
            }
            .layoutPriority(1)
            .frame(maxWidth: .infinity)
        }
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .frame(minHeight: 55) // Investigate why existing nav bar is of height 55 instead of 44
        .background(Color(viewConfig.theme.backgroundColor))
    }
    
    struct BackButton: View {
        
        @EnvironmentObject var host: AmitySwiftUIHostWrapper
        @EnvironmentObject var viewConfig: AmityViewConfigController
        
        var body: some View {
            let backIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .backButtonElement, key: "icon", of: String.self) ?? "backIcon")
            Image(backIcon)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 20)
                .onTapGesture {
                    host.controller?.navigationController?.popViewController(animated: true)
                }
                .isHidden(viewConfig.isHidden(elementId: .backButtonElement))
                .padding(.horizontal, 8) // We add padding here to increase tappable area
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
