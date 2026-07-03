//
//  SharedEventComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 4/11/25.
//

import SwiftUI

struct EventComponentEmptyState: View {

    @StateObject private var viewConfig = AmityViewConfigController(pageId: nil)

    var body: some View {
        HStack {
            Spacer()

            AmityEmptyStateView(configuration: .init(image: AmityIcon.eventEmptyStateIcon.rawValue, title: AmityLocalizedStringSet.Social.eventEmptyStateNoEvents.localizedString, subtitle: nil, iconSize: .init(width: 60, height: 60), renderingMode: .template, iconTintColor: viewConfig.theme.baseColorShade4, imageBottomPadding: 12, tapAction: nil))

            Spacer()
        }
        .updateTheme(with: viewConfig)
    }
}

struct EventComponentLoadingState: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            EventCardSkeletonView(style: .list)
            EventCardSkeletonView(style: .list)
            EventCardSkeletonView(style: .list)
            
            Spacer()
        }
    }
}
