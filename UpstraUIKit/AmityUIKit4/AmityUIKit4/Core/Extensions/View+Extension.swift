//
//  View+.swift
//  AmityUIKit4
//
//  Created by Prisa on 2/7/2569 BE.
//


extension View {
    /// Overlays a bottom-to-top dark gradient, used to improve text/icon legibility over thumbnails.
    public func applyDefaultThumbnailGradient(isVisible: Bool, cornerRadius: CGFloat = 8) -> some View {
        overlay(
            LinearGradient(colors: [Color.black.opacity(0.4), Color.black.opacity(0)],
                           startPoint: .bottom,
                           endPoint: .top)
                .cornerRadius(cornerRadius, corners: .allCorners)
                .opacity(isVisible ? 1 : 0)
            , alignment: .center)
    }
    
}

extension View {
    func adAvatarPlaceholderView(viewConfig: AmityViewConfigController, size: CGFloat) -> some View {
        AdAvatarPlaceholder(viewConfig: viewConfig, size: size)
    }
}

private struct AdAvatarPlaceholder: View {
    let viewConfig: AmityViewConfigController
    let size: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let iconSize: CGFloat = {
            switch size {
            case 32: return 16
            case 40: return 24
            case 56: return 33.6
            case 64: return 32
            default: return size * 0.50
            }
        }()

        ZStack {
            Color(colorScheme == .dark
                  ? viewConfig.theme.primaryColor.blend(.shade1)
                  : viewConfig.theme.primaryColor.blend(.shade2))
            Image(AmityIcon.adAvatarPlaceholder.imageResource)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize)
        }
        .frame(width: size, height: size)
        .cornerRadius(.infinity)
    }
}


extension View {
    func defaultCommunityPlaceholderView(viewConfig: AmityViewConfigController, size: CGFloat) -> some View {
        DefaultCommunityPlaceholder(viewConfig: viewConfig, size: size)
    }
}

private struct DefaultCommunityPlaceholder: View {
    let viewConfig: AmityViewConfigController
    let size: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(colorScheme == .dark
                  ? viewConfig.theme.primaryColor.blend(.shade1)
                  : viewConfig.theme.primaryColor.blend(.shade2))
                .frame(width: size, height: size)

            Image(AmityIcon.defaultCommunity.imageResource)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.6, height: size * 0.6) // scale icon relative to bg
        }
        .frame(width: size, height: size)
    }
}


extension View {
    func categoryPlaceholderView(viewConfig: AmityViewConfigController, size: CGFloat) -> some View {
        CategoryPlaceholder(viewConfig: viewConfig, size: size)
    }
}

private struct CategoryPlaceholder: View {
    let viewConfig: AmityViewConfigController
    let size: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(colorScheme == .dark
                  ? viewConfig.theme.primaryColor.blend(.shade1)
                  : viewConfig.theme.primaryColor.blend(.shade2))
                .frame(width: size, height: size)

            Image(AmityIcon.communityCategoryPlaceholder.imageResource)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.45, height: size * 0.45) // scale icon relative to bg
        }
        .frame(width: size, height: size)
    }
}

