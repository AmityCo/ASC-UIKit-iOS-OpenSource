//
//  AmityEmptyStateView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 14/3/2567 BE.
//

import SwiftUI

public struct AmityEmptyStateView: View {
    
    public let configuration: EmptyStateConfiguration
    
    public init(configuration: EmptyStateConfiguration) {
        self.configuration = configuration
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if let icon = configuration.image {
                Image(ImageResource(name: icon, bundle: AmityUIKit4Manager.bundle))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 24)
            }
            
            if let title = configuration.title {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "#898E9E"))
                    .padding(.top, 24)
            }
            
            if let subtitle = configuration.subtitle {
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#898E9E"))
                    .multilineTextAlignment(.center)
                    .padding(.top, configuration.title == nil ? 24 : 4)
            }
        }
        .padding(.horizontal, 16)
        .onTapGesture {
            configuration.tapAction?()
        }
    }
    
    public struct EmptyStateConfiguration {        
        public let image: String?
        public let title: String?
        public let subtitle: String?
        public let tapAction: DefaultTapAction?
        
        public init(image: String?, title: String?, subtitle: String?, tapAction: DefaultTapAction?) {
            self.image = image
            self.title = title
            self.subtitle = subtitle
            self.tapAction = tapAction
        }
        
        internal static let previewWithoutTitle = EmptyStateConfiguration(image: AmityIcon.Chat.emptyStateMessage.rawValue, title: nil, subtitle: "Couldn't load chat", tapAction: nil)
        internal static let previewWithTitle = EmptyStateConfiguration(image: AmityIcon.Chat.emptyStateMessage.rawValue, title: "You are banned from chat", subtitle: "You won’t be able to participate in this chat until you’ve been unbanned.", tapAction: { })
    }
}

#if DEBUG
#Preview {
    AmityEmptyStateView(configuration: AmityEmptyStateView.EmptyStateConfiguration.previewWithoutTitle)
        .preferredColorScheme(.dark)
        .colorScheme(.dark)
}
#endif
