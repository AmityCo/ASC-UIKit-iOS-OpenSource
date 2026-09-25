//
//  AmityNetworkLogRow.swift
//  SampleApp
//

import SwiftUI

/// One line of the timeline.
///
/// Renders a precomputed ``AmityNetworkLogEntry``: it formats nothing itself, and holds no
/// reference to the underlying SDK record, so a visible row never blocks collector eviction.
/// - Note: Gated to iOS 15. The sample app targets iOS 14 to match the SDK, but this is a
///   debug-only surface and testers run current iOS, so it uses modern SwiftUI rather
///   than constraining the whole viewer to iOS 14 idioms.
@available(iOS 15.0, *)
struct AmityNetworkLogRow: View {

    let entry: AmityNetworkLogEntry
    var isExpanded: Bool = false
    var indentLevel: Int = 0
    var onTap: (() -> Void)? = nil
    var onLongPress: (() -> Void)? = nil

    var body: some View {
        Group {
            switch entry.variant {
            case .dropped: droppedRow
            case .group:   gridRow(isGroup: true)
            default:       gridRow(isGroup: false)
            }
        }
        .frame(height: NetworkLogTheme.rowHeight)
        .frame(maxWidth: .infinity)
        .background(rowBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(NetworkLogTheme.baseShade4).frame(height: 0.5)
        }
        .contentShape(Rectangle())
        .onTapGesture { if entry.variant != .dropped { onTap?() } }
        .onLongPressGesture { if entry.variant != .dropped { onLongPress?() } }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Variants

    /// The four-column grid shared by the request, message, state and group variants.
    private func gridRow(isGroup: Bool) -> some View {
        HStack(spacing: NetworkLogTheme.columnGap) {
            Text(entry.timestampLabel)
                .font(NetworkLogTheme.rowTimestamp)
                .foregroundColor(NetworkLogTheme.baseShade2)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(width: NetworkLogTheme.timestampColumnWidth, alignment: .leading)

            typeChip

            HStack(spacing: 4) {
                if isGroup {
                    Text(isExpanded ? "▾" : "▸")
                        .font(NetworkLogTheme.rowPrimary)
                        .foregroundColor(NetworkLogTheme.baseShade1)
                }
                primaryLabel(isGroup: isGroup)
                if let secondary = entry.secondaryLabel {
                    Text(secondary)
                        .font(NetworkLogTheme.rowTimestamp)
                        .foregroundColor(NetworkLogTheme.baseShade1)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let status = entry.statusLabel {
                Text(status)
                    .font(NetworkLogTheme.rowStatus)
                    .foregroundColor(NetworkLogTheme.statusColor(entry.statusClass))
                    .lineLimit(1)
            } else if let duration = entry.durationLabel {
                Text(duration)
                    .font(NetworkLogTheme.rowStatus)
                    .foregroundColor(NetworkLogTheme.baseShade2)
                    .lineLimit(1)
            }
        }
        .padding(.leading, indentLevel > 0 ? NetworkLogTheme.rowIndentedLeading : NetworkLogTheme.rowHorizontalPadding)
        .padding(.trailing, NetworkLogTheme.rowHorizontalPadding)
    }

    private func primaryLabel(isGroup: Bool) -> some View {
        Text(entry.primaryLabel)
            .font(isGroup ? NetworkLogTheme.rowPrimaryBold : NetworkLogTheme.rowPrimary)
            .foregroundColor(NetworkLogTheme.base)
            .lineLimit(1)
            // Paths and topics truncate at the head: every row shares a host, so tail
            // truncation makes the first forty characters of every row identical.
            .truncationMode(isGroup ? .tail : .head)
    }

    private var typeChip: some View {
        let style = NetworkLogTheme.chipStyle(for: entry.type)
        return Text(style.label)
            .font(NetworkLogTheme.typeChip)
            .foregroundColor(style.foreground)
            .frame(width: NetworkLogTheme.typeChipWidth)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 3).fill(style.background))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(style.isOutlined ? style.foreground : .clear, lineWidth: 1)
            )
    }

    private var droppedRow: some View {
        Text(entry.primaryLabel)
            .font(NetworkLogTheme.droppedMarker)
            .foregroundColor(NetworkLogTheme.warning)
            .frame(maxWidth: .infinity)
    }

    private var rowBackground: Color {
        switch entry.variant {
        case .group, .dropped: return NetworkLogTheme.backgroundShade1
        // Children of an expanded group revert to the plain background, so the shaded band
        // reads as the group header rather than the whole expanded block.
        default:               return NetworkLogTheme.background
        }
    }

    /// One coherent sentence rather than six fragments.
    private var accessibilityLabel: String {
        switch entry.variant {
        case .dropped:
            return entry.primaryLabel
        case .group:
            return "\(NetworkLogTheme.chipStyle(for: entry.type).label) group, \(entry.childCount ?? 0) requests, \(entry.failureCount ?? 0) failed, \(isExpanded ? "expanded" : "collapsed")"
        default:
            let status = entry.statusLabel ?? entry.durationLabel ?? ""
            return "\(entry.timestampLabel), \(NetworkLogTheme.chipStyle(for: entry.type).label), \(entry.secondaryLabel ?? "") \(entry.primaryLabel), \(status)"
        }
    }
}
