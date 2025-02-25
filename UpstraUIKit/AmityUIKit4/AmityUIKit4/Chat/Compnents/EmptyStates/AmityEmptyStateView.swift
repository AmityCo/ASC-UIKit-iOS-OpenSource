//
//  AmityEmptyStateView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 14/3/2567 BE.
//

import SwiftUI

public struct AmityEmptyStateView: View {
    
    @StateObject private var viewConfig: AmityViewConfigController = AmityViewConfigController(pageId: nil)
    
    public let configuration: Configuration
    
    public init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if let icon = configuration.image {
                Image(ImageResource(name: icon, bundle: AmityUIKit4Manager.bundle))
                    .renderingMode(configuration.renderingMode)
                    .resizable()
                    .scaledToFit()
                    .frame(size: configuration.iconSize)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
            }
            
            if let title = configuration.title {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    .padding(.top, 24)
            }
            
            if let subtitle = configuration.subtitle {
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    .multilineTextAlignment(.center)
                    .padding(.top, configuration.title == nil ? 24 : 4)
            }
        }
        .padding(.horizontal, 16)
        .onTapGesture {
            // Haptic feedback
            ImpactFeedbackGenerator.impactFeedback(style: .light)
            
            configuration.tapAction?()
        }
    }
    
    public struct Configuration {
        public let image: String?
        public let title: String?
        public let subtitle: String?
        public let tapAction: DefaultTapAction?
        public let iconSize: CGSize
        public let renderingMode: Image.TemplateRenderingMode
        
        public init(image: String?, title: String?, subtitle: String?, iconSize: CGSize = CGSize(width: 28, height: 24), renderingMode: Image.TemplateRenderingMode = .template, tapAction: DefaultTapAction?) {
            self.image = image
            self.title = title
            self.subtitle = subtitle
            self.tapAction = tapAction
            self.iconSize = iconSize
            self.renderingMode = renderingMode
        }
        
        internal static let previewWithoutTitle = Configuration(image: AmityIcon.Chat.emptyStateMessage.rawValue, title: nil, subtitle: "Couldn't load chat", tapAction: nil)
        internal static let previewWithTitle = Configuration(image: AmityIcon.Chat.emptyStateMessage.rawValue, title: "You are banned from chat", subtitle: "You won’t be able to participate in this chat until you’ve been unbanned.", tapAction: { })
    }
}

#if DEBUG
#Preview {
    AmityEmptyStateView(configuration: AmityEmptyStateView.Configuration.previewWithoutTitle)
        .preferredColorScheme(.dark)
        .colorScheme(.dark)
}
#endif
