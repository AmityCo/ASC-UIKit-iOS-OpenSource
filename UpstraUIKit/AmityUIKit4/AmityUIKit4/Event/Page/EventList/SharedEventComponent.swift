//
//  SharedEventComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 4/11/25.
//

import SwiftUI

struct EventComponentEmptyState: View {

    var body: some View {
        HStack {
            Spacer()

            AmityEmptyStateView(configuration: .init(image: AmityIcon.eventEmptyStateIcon.rawValue, title: AmityLocalizedStringSet.Social.eventEmptyStateNoEvents.localizedString, subtitle: nil, iconSize: .init(width: 60, height: 60), renderingMode: .original, imageBottomPadding: 12, tapAction: nil))

            Spacer()
        }
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
