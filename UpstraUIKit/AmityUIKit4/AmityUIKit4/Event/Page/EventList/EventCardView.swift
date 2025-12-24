//
//  EventCardView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 30/10/25.
//

import SwiftUI
import AmitySDK
import Foundation

enum EventCardStyle {
    case large
    case medium
    case list
    
    var height: CGFloat {
        switch self {
        case .large:
            return 194
        case .medium:
            return 142
        case .list:
            return 80
        }
    }
}

struct EventCardView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let style: EventCardStyle
    let imageURL: String?
    let badge: String
    let time: String
    let title: String
    let author: String
    let isBrand: Bool
    let isHost: Bool
    
    init(
        style: EventCardStyle,
        imageURL: String? = nil,
        badge: String = "In-person",
        time: String,
        title: String,
        author: String,
        isVerified: Bool = false
    ) {
        self.style = style
        self.imageURL = imageURL
        self.badge = badge
        self.time = time
        self.title = title
        self.author = author
        self.isBrand = isVerified
        self.isHost = false
    }
    
    init(style: EventCardStyle, event: AmityEvent) {
        self.style = style
        self.title = event.title
        self.author = event.creator?.displayName ?? "-"
        self.time = EventTimestamp(startTime: event.startTime, endTime: event.endTime).formattedTime
        self.badge = event.type == .inPerson ? "In-person" : "Virtual"
        self.isBrand = event.creator?.isBrand ?? false
        self.imageURL = event.coverImage?.mediumFileURL
        self.isHost = event.creator?.userId == AmityUIKit4Manager.client.currentUserId
    }
    
    var body: some View {
        switch style {
        case .large:
            largeCard
        case .medium:
            mediumCard
        case .list:
            listCard
        }
    }
    
    private var largeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                
                AsyncImage(placeholder: AmityIcon.eventImagePlaceholder.imageResource, url: URL(string: imageURL ?? ""))
                .frame(height: style.height)
                .cornerRadius(8, corners: .allCorners)
                .clipped()
                .contentShape(Rectangle())
                
                eventBadgeView
            }
            
            eventInfo
                .padding(.top, 12)
        }
        .background(Color.white)
        .cornerRadius(8)
    }
    
    private var mediumCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                AsyncImage(placeholder: AmityIcon.eventImagePlaceholder.imageResource, url: URL(string: imageURL ?? ""))
                .frame(height: style.height)
                
                eventBadgeView
            }
            
            eventInfo
                .padding(12)
        }
        .frame(width: 250)
        .background(Color.white)
        .cornerRadius(8)
        .border(radius: 8, borderColor: Color(viewConfig.theme.baseColorShade4), borderWidth: 1)
    }
    
    private var listCard: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                AsyncImage(placeholder: AmityIcon.eventImagePlaceholder.imageResource, url: URL(string: imageURL ?? ""))
                .frame(width: 142, height: style.height)
                .cornerRadius(8)
                
                eventBadgeView
            }
            .frame(width: 142, height: 80)
            
            eventInfo
            
            Spacer(minLength: 1)
        }
        .background(Color.white)
    }
    
    var avatarPlaceHolderView: some View {
        Rectangle()
            .fill(Color(viewConfig.theme.baseColorShade4))
    }
    
    var eventBadgeView: some View {
        HStack {
            eventTypeBadge
            
            Spacer()
            
            eventHostBadge
                .opacity(isHost ? 1 : 0)
        }
        .padding(style == .large ? 8 : 4)
    }
    
    var eventTypeBadge: some View {
        Text(badge)
            .applyTextStyle(.captionBold(.white))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.5))
            )
            .frame(height: 22)
    }
    
    var eventHostBadge: some View {
        Image(AmityIcon.eventHostBadge.imageResource)
            .resizable()
            .frame(width: 16, height: 16)
            .padding(4)
            .background(Color(hex: "#EAE2FF"))
            .clipped()
            .clipShape(Circle())
    }
    
    @ViewBuilder
    var eventInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(time)
                .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(2)
            
            Text(title)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(style == .large ? 2 : 1)
            
            HStack(spacing: 4) {
                Text("By \(author)")
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    .lineLimit(1)

                if isBrand {
                    Image(AmityIcon.brandBadge.imageResource)
                        .resizable()
                        .frame(width: style == .large ? 20 : 16, height: style == .large ? 20 : 16)
                }
            }
        }
    }
}

struct EventCardSkeletonView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let style: EventCardStyle
    
    init(style: EventCardStyle) {
        self.style = style
    }
    
    var body: some View {
        switch style {
        case .large:
            largeCard
        case .medium:
            mediumCard
        case .list:
            listCard
        }
    }
    
    var largeCard: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: style.height)
                .cornerRadius(12)
            
            SkeletonRectangle(height: 12, width: 140)
                .padding(.top, 16)
            SkeletonRectangle(height: 12, width: 244)
            SkeletonRectangle(height: 12, width: 100)
                .padding(.bottom, 16)
        }
    }
    
    var mediumCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 250, height: style.height)
            
            VStack(alignment: .leading) {
                SkeletonRectangle(height: 12, width: 112)
                SkeletonRectangle(height: 12, width: 196)
                SkeletonRectangle(height: 12, width: 80)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
        .frame(width: 250)
        .background(Color.white)
        .cornerRadius(8)
        .border(radius: 8, borderColor: Color(viewConfig.theme.baseColorShade4), borderWidth: 1)
    }
    
    var listCard: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 142, height: style.height)
                .cornerRadius(12)
            
            VStack(alignment: .leading) {
                SkeletonRectangle(height: 12, width: 140)
                SkeletonRectangle(height: 12, width: 162)
                SkeletonRectangle(height: 12, width: 100)
            }
            
            Spacer(minLength: 1)
        }
    }
    
}

struct EventTimestamp {
    
    var formattedTime: String = ""
    
    init(startTime: Date, endTime: Date) {
        if Calendar.current.isDateInYesterday(startTime) {
            let finalStartTime = Formatters.eventTimeFormatter.string(from: startTime)
            let finalEndTime = formatEndTime(endTime: endTime, startTime: startTime)
            formattedTime = "Yesterday, \(finalStartTime) to \(finalEndTime)"
        } else if Calendar.current.isDateInToday(startTime) {
            let finalStartTime = Formatters.eventTimeFormatter.string(from: startTime)
            let finalEndTime = formatEndTime(endTime: endTime, startTime: startTime)
            formattedTime = "Today, \(finalStartTime) to \(finalEndTime)"
        } else if Calendar.current.isDateInTomorrow(startTime) {
            let finalStartTime = Formatters.eventTimeFormatter.string(from: startTime)
            let finalEndTime = formatEndTime(endTime: endTime, startTime: startTime)
            formattedTime = "Tomorrow, \(finalStartTime) to \(finalEndTime)"
        } else {
            let finalStartTime = Formatters.eventDateAndTimeFormatter.string(from: startTime)
            let finalEndTime = formatEndTime(endTime: endTime, startTime: startTime)
            formattedTime = "\(finalStartTime) to \(finalEndTime)"

        }
    }
    
    private func formatEndTime(endTime: Date, startTime: Date) -> String {
        if Calendar.current.isDate(endTime, inSameDayAs: startTime) {
            return Formatters.eventTimeFormatter.string(from: endTime)
        } else {
            return Formatters.eventDateAndTimeFormatter.string(from: endTime)
        }
    }
}



