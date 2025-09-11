//
//  PollDurationSection.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 18/7/25.
//

import SwiftUI

struct PollDurationSection: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @Binding var duration: PollDuration
    var onTapAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            PollSectionHeader(title: AmityLocalizedStringSet.Social.pollDurationTitle.localizedString, description: AmityLocalizedStringSet.Social.pollDurationDesc.localizedString)
            
            Button(action: {
                onTapAction()
            }, label: {
                VStack(spacing: 0) {
                    HStack {
                        Text(duration.value)
                            .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                    }
                    .padding(.bottom, 16)
                    .padding(.top, 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    
                    Divider()
                }
            })
            
            if !duration.isCustomDate {
                let endDate = Calendar.current.date(byAdding: .day, value: duration.unit, to: Date())
                Text(AmityLocalizedStringSet.Social.pollEndsOnLabel.localizedString + " " + Formatters.pollDurationFormatter.string(from: endDate ?? Date()))
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
            }
        }
    }
}
