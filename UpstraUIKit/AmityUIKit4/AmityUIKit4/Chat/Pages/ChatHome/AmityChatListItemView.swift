//
//  AmityChatListItemView.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

struct AmityChatListItemView: View {

    // MARK: Inputs

    let channel: AmityChannel
    let searchQuery: String
    let isArchived: Bool
    let searchMessage: AmityMessage?

    let theme: AmityThemeColor

    init(
        channel: AmityChannel,
        searchQuery: String = "",
        isArchived: Bool = false,
        searchMessage: AmityMessage? = nil,
        theme: AmityThemeColor
    ) {
        self.channel = channel
        self.searchQuery = searchQuery
        self.isArchived = isArchived
        self.searchMessage = searchMessage
        self.theme = theme
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            avatarView
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                nameRow
                previewRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            rightColumn
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: 82, alignment: .top)
        .background(Color(theme.backgroundColor))
    }

    // MARK: - Name row

    @ViewBuilder
    private var nameRow: some View {
        let highlightName = !searchQuery.isEmpty && searchMessage == nil
        let displayName = resolvedDisplayName

        if channel.channelType == .community {
            HStack(spacing: 2) {
                Group {
                    if highlightName, hasWordBoundaryMatch(in: displayName, query: searchQuery) {
                        highlightedNameText(displayName, query: searchQuery)
                    } else {
                        Text(displayName)
                            .applyTextStyle(.bodyBold(Color(theme.baseColor)))
                    }
                }
                .lineLimit(1)

                Text("(\(formattedCompactCount(channel.memberCount)))")
                    .applyTextStyle(.caption(Color(theme.baseColorShade2)))
                    .lineLimit(1)
                    .fixedSize()
            }
        } else {
            let nameColor: Color = isOtherUserDeleted
                ? Color(theme.baseColorShade2)
                : Color(theme.baseColor)
            HStack(spacing: 4) {
                Group {
                    if highlightName, hasWordBoundaryMatch(in: displayName, query: searchQuery) {
                        highlightedNameText(displayName, query: searchQuery)
                    } else {
                        Text(displayName)
                            .applyTextStyle(.bodyBold(nameColor))
                    }
                }
                .lineLimit(1)
            }
        }
    }

    // MARK: - Preview row

    @ViewBuilder
    private var previewRow: some View {
        let preview = resolvedPreview
        HStack(spacing: 4) {
            if let icon = preview.icon {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color(theme.baseColorShade2))
            }

            let highlightPreview = !searchQuery.isEmpty
                && searchMessage != nil
                && hasWordBoundaryMatch(in: preview.text, query: searchQuery)

            Group {
                if highlightPreview {
                    highlightedPreviewText(preview.text, query: searchQuery)
                } else {
                    Text(preview.text)
                        .applyTextStyle(.body(Color(theme.baseColorShade2)))
                }
            }
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    // MARK: - Right column (timestamp + badges)

    @ViewBuilder
    private var rightColumn: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text(formattedDate(channel.lastActivity ?? channel.updatedAt ?? Date()))
                .applyTextStyle(.caption(Color(theme.baseColorShade2)))
                .lineLimit(1)
                .fixedSize()

            HStack(spacing: 4) {
                if isArchived {
                    archivedBadge
                }
                if channel.isMentioned {
                    mentionIndicator
                }
                if channel.unreadCount > 0 {
                    unreadBadge
                }
            }
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private var avatarView: some View {
        let resolvedURL: URL? = {
            if channel.channelType == .conversation {
                let currentUserId = AmityUIKit4Manager.client.currentUserId ?? ""
                let other = channel.previewMembers.first(where: { $0.userId != currentUserId })
                if let urlStr = other?.user?.getAvatarInfo()?.fileURL { return URL(string: urlStr) }
            }
            if let urlStr = channel.getAvatarInfo()?.fileURL { return URL(string: urlStr) }
            return nil
        }()

        if channel.channelType == .conversation {
            if isOtherUserDeleted {
                ZStack {
                    Circle()
                        .fill(Color(theme.secondaryColor.blend(.shade2)))
                    Image(AmityIcon.Chat.deletedUserAvatarIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(theme.backgroundColor))
                        .frame(width: 15, height: 16)
                }
                .clipShape(Circle())
            } else {
                ZStack {
                    let initial = String(
                        resolvedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).first ?? " "
                    ).uppercased()
                    Circle()
                        .fill(Color(theme.primaryColor.blend(.shade2)))
                        .overlay(
                            Text(initial)
                                .applyTextStyle(.custom(40 * 0.55, .regular, .white))
                        )
                    AsyncImage(placeholderView: { Color.clear }, url: resolvedURL)
                        .clipShape(Circle())
                }
                .clipShape(Circle())
            }
        } else {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(theme.primaryColor.blend(.shade2)))
                        .overlay(
                            Image(AmityIcon.Chat.groupAvatarPlaceholderIcon.imageResource)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                        )
                    AsyncImage(placeholderView: { Color.clear }, url: resolvedURL)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                if channel.isPublic == false {
                    privateBadge.offset(x: 1, y: 1)
                }
            }
        }
    }

    private var privateBadge: some View {
        ZStack {
            Circle().fill(Color(theme.primaryColor.blend(.shade2)))
            Circle().stroke(Color(theme.backgroundColor), lineWidth: 1)
            Image(AmityIcon.Chat.privateChannelIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 8, height: 8)
                .foregroundColor(Color(theme.backgroundColor))
        }
        .frame(width: 16, height: 16)
    }

    // MARK: - Badges

    private var archivedBadge: some View {
        HStack(spacing: 1) {
            Image(AmityIcon.Chat.archiveBadgeIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundColor(Color(theme.baseColorShade1))
            Text(AmityLocalizedStringSet.Chat.Archived.label.localizedString)
                .applyTextStyle(.custom(11, .regular, Color(theme.baseColorShade1)))
        }
        .padding(EdgeInsets(top: 3.5, leading: 4, bottom: 3.5, trailing: 6))
        .background(
            Capsule().fill(Color(theme.baseColorShade4))
        )
    }

    private var mentionIndicator: some View {
        ZStack {
            Circle().fill(Color(theme.primaryColor.blend(.shade3)))
            Image(AmityIcon.Chat.roomMentionIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundColor(Color(theme.primaryColor))
        }
        .frame(width: 24, height: 24)
    }

    private var unreadBadge: some View {
        Text(channel.unreadCount > 99 ? "99+" : "\(channel.unreadCount)")
            .applyTextStyle(.custom(12, .bold, .white))
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(theme.alertColor)))
    }

    // MARK: - Resolved display name

    private var resolvedDisplayName: String {
        if channel.channelType == .conversation {
            let currentUserId = AmityUIKit4Manager.client.currentUserId ?? ""
            let other = channel.previewMembers.first(where: { $0.userId != currentUserId })
            let name = other?.displayName ?? other?.user?.displayName
            if let name, !name.isEmpty, other?.user?.isDeleted != true {
                return name
            }
            return AmityLocalizedStringSet.Chat.deletedUser.localizedString
        }
        return channel.displayName ?? ""
    }

    private var isOtherUserDeleted: Bool {
        guard channel.channelType == .conversation else { return false }
        let currentUserId = AmityUIKit4Manager.client.currentUserId ?? ""
        let other = channel.previewMembers.first(where: { $0.userId != currentUserId })
        if other?.user?.isDeleted == true { return true }
        let name = other?.displayName ?? other?.user?.displayName
        return (name?.isEmpty ?? true)
    }

    // MARK: - Resolved preview (icon + text)

    private var resolvedPreview: (text: String, icon: ImageResource?) {
        if let msg = searchMessage {
            return previewFromMessage(isDeleted: msg.isDeleted, dataType: msg.messageType, data: msg.data, isSearch: true)
        }
        if let prev = channel.messagePreview {
            return previewFromMessage(isDeleted: prev.isDeleted, dataType: prev.dataType, data: prev.data, isSearch: false)
        }
        return (AmityLocalizedStringSet.Chat.Preview.noMessageYet.localizedString, nil)
    }

    private func previewFromMessage(
        isDeleted: Bool,
        dataType: AmityMessageType,
        data: [String: Any]?,
        isSearch: Bool
    ) -> (text: String, icon: ImageResource?) {
        if isDeleted {
            return (
                AmityLocalizedStringSet.Chat.Preview.messageDeleted.localizedString,
                AmityIcon.Chat.previewDeletedMessageIcon.imageResource
            )
        }
        switch dataType {
        case .text:
            let text = (data?["text"] as? String) ?? ""
            return (text, nil)
        case .image:
            let key = AmityLocalizedStringSet.Chat.Preview.bannerPhoto
            return (key.localizedString, AmityIcon.Chat.previewImageMessageIcon.imageResource)
        case .video:
            let key = AmityLocalizedStringSet.Chat.Preview.bannerVideo
            return (key.localizedString, AmityIcon.Chat.previewVideoMessageIcon.imageResource)
        case .file, .audio:
            return (AmityLocalizedStringSet.Chat.Preview.messageNoPreview.localizedString, nil)
        case .custom:
            let text = (data?["text"] as? String) ?? AmityLocalizedStringSet.Chat.Preview.messageNoContent.localizedString
            return (text, nil)
        @unknown default:
            return (AmityLocalizedStringSet.Chat.Preview.messageNoContent.localizedString, nil)
        }
    }

    // MARK: - Date

    private static let dateFormatterLocale: Locale = {
        if let first = Locale.preferredLanguages.first {
            return Locale(identifier: first)
        }
        return Locale.current
    }()

    private func formattedDate(_ date: Date) -> String {
        let now = Date()
        let diff = now.timeIntervalSince(date)
        let minutes = Int(diff / 60)
        let hours = Int(diff / 3600)
        let days = Int(diff / 86400)
        let weeks = days / 7
        let years = days / 365

        if years >= 1 {
            let formatter = DateFormatter()
            formatter.locale = Self.dateFormatterLocale
            formatter.dateFormat = "d MMM yyyy"
            return formatter.string(from: date)
        } else if weeks >= 1 {
            let formatter = DateFormatter()
            formatter.locale = Self.dateFormatterLocale
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        } else if days >= 1 {
            return "\(days)\(AmityLocalizedStringSet.General.timeDaysSuffix.localizedString)"
        } else if hours >= 1 {
            return "\(hours)\(AmityLocalizedStringSet.General.timeHoursSuffix.localizedString)"
        } else if minutes >= 1 {
            return "\(minutes)\(AmityLocalizedStringSet.General.timeMinutesSuffix.localizedString)"
        } else {
            return AmityLocalizedStringSet.Chat.Home.timestampNow.localizedString
        }
    }

    // MARK: - Compact count formatter (e.g. 1.2k)

    private func formattedCompactCount(_ count: Int) -> String {
        if count < 1000 { return "\(count)" }
        if count < 1_000_000 {
            let value = Double(count) / 1000.0
            return String(format: "%.1fk", value).replacingOccurrences(of: ".0k", with: "k")
        }
        let value = Double(count) / 1_000_000.0
        return String(format: "%.1fM", value).replacingOccurrences(of: ".0M", with: "M")
    }

    // MARK: - Word-boundary match

    private func findWordBoundaryMatches(in text: String, query: String) -> [String.Index] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty, trimmedQuery.count >= 3 else { return [] }

        let lowerText = text.lowercased()
        let lowerQuery = trimmedQuery.lowercased()
        var results: [String.Index] = []
        var searchStart = lowerText.startIndex

        while let range = lowerText.range(of: lowerQuery, range: searchStart..<lowerText.endIndex) {
            let isAtStart = range.lowerBound == lowerText.startIndex
            let isAfterSpace: Bool = {
                guard !isAtStart else { return false }
                let prev = lowerText.index(before: range.lowerBound)
                return lowerText[prev] == " "
            }()
            if isAtStart || isAfterSpace {
                let offset = lowerText.distance(from: lowerText.startIndex, to: range.lowerBound)
                if let mapped = text.index(text.startIndex, offsetBy: offset, limitedBy: text.endIndex) {
                    results.append(mapped)
                }
            }
            searchStart = range.upperBound
        }
        return results
    }

    private func hasWordBoundaryMatch(in text: String, query: String) -> Bool {
        !findWordBoundaryMatches(in: text, query: query).isEmpty
    }

    // MARK: - Highlighted name text

    private func highlightedNameText(_ text: String, query: String) -> Text {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let queryLen = trimmedQuery.count
        let matches = findWordBoundaryMatches(in: text, query: trimmedQuery)
        let nameFont = Font.system(size: 15, weight: .semibold)
        guard !matches.isEmpty else {
            return Text(text)
                .font(nameFont)
                .foregroundColor(Color(theme.baseColor))
        }

        var result = Text("")
        var cursor = text.startIndex

        for matchStart in matches {
            if cursor < matchStart {
                let chunk = String(text[cursor..<matchStart])
                result = result + Text(chunk)
                    .font(nameFont)
                    .foregroundColor(Color(theme.baseColor))
            }
            let matchEnd = text.index(matchStart, offsetBy: queryLen, limitedBy: text.endIndex) ?? text.endIndex
            let matchedChunk = String(text[matchStart..<matchEnd])
            result = result + Text(matchedChunk)
                .font(nameFont)
                .foregroundColor(Color(theme.primaryColor))
            cursor = matchEnd
        }
        if cursor < text.endIndex {
            let chunk = String(text[cursor..<text.endIndex])
            result = result + Text(chunk)
                .font(nameFont)
                .foregroundColor(Color(theme.baseColor))
        }
        return result
    }

    // MARK: - Highlighted preview text (with 80-char window)

    private func highlightedPreviewText(_ text: String, query: String) -> Text {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let queryLen = trimmedQuery.count
        let maxChars = 80
        let truncated = text.count > maxChars
            ? String(text.prefix(maxChars))
            : text
        let matches = findWordBoundaryMatches(in: truncated, query: trimmedQuery)
        let bodyFont = Font.system(size: 15, weight: .regular)
        let bodyBoldFont = Font.system(size: 15, weight: .semibold)
        guard !matches.isEmpty else {
            return Text(truncated)
                .font(bodyFont)
                .foregroundColor(Color(theme.baseColorShade2))
        }

        var result = Text("")
        var cursor = truncated.startIndex
        for matchStart in matches {
            if cursor < matchStart {
                let chunk = String(truncated[cursor..<matchStart])
                result = result + Text(chunk)
                    .font(bodyFont)
                    .foregroundColor(Color(theme.baseColorShade2))
            }
            let matchEnd = truncated.index(matchStart, offsetBy: queryLen, limitedBy: truncated.endIndex) ?? truncated.endIndex
            let matchedChunk = String(truncated[matchStart..<matchEnd])
            result = result + Text(matchedChunk)
                .font(bodyBoldFont)
                .foregroundColor(Color(theme.baseColor))
            cursor = matchEnd
        }
        if cursor < truncated.endIndex {
            let chunk = String(truncated[cursor..<truncated.endIndex])
            result = result + Text(chunk)
                .font(bodyFont)
                .foregroundColor(Color(theme.baseColorShade2))
        }
        if text.count > maxChars {
            result = result + Text("...")
                .font(bodyFont)
                .foregroundColor(Color(theme.baseColorShade2))
        }
        return result
    }
}
