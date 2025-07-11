//
//  VideoFeedTabButton.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 19/6/25.
//

import SwiftUI

enum VideoFeedTab: String, Identifiable {
    case videos
    case clips
    
    var id: String {
        return self.rawValue
    }
}

struct VideoFeedTabButton: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    private let selected: Bool
    private let title: String
    private let action: () -> Void
    
    init(title: String, selected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.selected = selected
        self.action = action
    }
    
    var body: some View {
        HStack {
            Text(title)
                .applyTextStyle(selected ? .bodyBold(Color(viewConfig.defaultLightTheme.backgroundColor)) : .body(Color(viewConfig.theme.baseColorShade1)))
                .padding([.leading, .trailing], 12)
        }
        .frame(height: 38)
        .background(selected ? Color(viewConfig.theme.primaryColor) : Color(viewConfig.theme.baseColorShade4))
        .clipShape(RoundedCorner())
        .onTapGesture {
            action()
        }
    }
}
