//
//  NetworkLogTheme.swift
//  SampleApp
//

import SwiftUI
import AmitySDK

/// Palette and type scale for the network log viewer.
///
/// `AmityThemeColor` is internal to AmityUIKit4, so the sample app cannot resolve the UIKit's
/// tokens directly. These are the same light/dark values, declared once here and never
/// inlined at a call site.
enum NetworkLogTheme {

    // MARK: - Base ramp

    static let background       = dynamic(light: 0xFFFFFF, dark: 0x191A20)
    static let backgroundShade1 = dynamic(light: 0xF6F7F8, dark: 0x24262E)
    static let base             = dynamic(light: 0x292B32, dark: 0xEBECEF)
    static let baseShade1       = dynamic(light: 0x636878, dark: 0xA5A9B5)
    static let baseShade2       = dynamic(light: 0x898E9E, dark: 0x898E9E)
    static let baseShade3       = dynamic(light: 0xA5A9B5, dark: 0x636878)
    static let baseShade4       = dynamic(light: 0xEBECEF, dark: 0x40434E)
    static let primary          = dynamic(light: 0x1054DE, dark: 0x4A82F2)
    static let alert            = dynamic(light: 0xFA4D30, dark: 0xFF7A62)
    static let warning          = dynamic(light: 0x8A5A00, dark: 0xE0A45C)

    // MARK: - Status colours

    static func statusColor(_ statusClass: AmityNetworkLogStatusClass) -> Color {
        switch statusClass {
        case .success:  return dynamic(light: 0x1F7A3D, dark: 0x5FCB86)
        case .neutral:  return baseShade1
        case .warning:  return warning
        case .error:    return alert
        case .inFlight: return baseShade2
        case .none:     return .clear
        }
    }

    // MARK: - Type-chip palette

    /// Six hues carry the activity family; fill versus outline carries the request/state
    /// split. A solid chip always has a request and a response; an outlined chip never does.
    /// Eight values stay distinguishable with six hues, which is what lets the set survive
    /// both themes and colour-vision differences.
    struct TypeChipStyle {
        let label: String
        let foreground: Color
        let background: Color
        let isOutlined: Bool
    }

    static func chipStyle(for type: AmityNetworkActivityType) -> TypeChipStyle {
        switch type {
        case .api:
            return TypeChipStyle(label: "API", foreground: dynamic(light: 0x1054DE, dark: 0x7FA5FF),
                                 background: dynamic(light: 0xE7EEFC, dark: 0x1A2440), isOutlined: false)
        case .upload:
            return TypeChipStyle(label: "UPLD", foreground: dynamic(light: 0x4C3FD6, dark: 0xA79CFB),
                                 background: dynamic(light: 0xEAE8FB, dark: 0x241F45), isOutlined: false)
        case .download:
            return TypeChipStyle(label: "DOWN", foreground: dynamic(light: 0x00707A, dark: 0x4FC0C8),
                                 background: dynamic(light: 0xDDF0F1, dark: 0x10312F), isOutlined: false)
        case .mediaSegment:
            return TypeChipStyle(label: "HLS", foreground: dynamic(light: 0x8A5A00, dark: 0xE0A45C),
                                 background: dynamic(light: 0xFAEFDC, dark: 0x35240F), isOutlined: false)
        case .image:
            // Image loads are the least diagnostic signal and should recede, so they reuse the
            // neutral ramp rather than inventing a hue.
            return TypeChipStyle(label: "IMG", foreground: dynamic(light: 0x636878, dark: 0xA5A9B5),
                                 background: dynamic(light: 0xEDEEF1, dark: 0x2B2E38), isOutlined: false)
        case .mqttMessage:
            return TypeChipStyle(label: "MQTT", foreground: dynamic(light: 0x8B2FB8, dark: 0xCF8CE8),
                                 background: dynamic(light: 0xF4E6FA, dark: 0x2C1938), isOutlined: false)
        case .mqttState:
            return TypeChipStyle(label: "CONN", foreground: dynamic(light: 0x8B2FB8, dark: 0xCF8CE8),
                                 background: .clear, isOutlined: true)
        case .streamState:
            return TypeChipStyle(label: "EVT", foreground: dynamic(light: 0x8A5A00, dark: 0xE0A45C),
                                 background: .clear, isOutlined: true)
        }
    }

    // MARK: - Type scale
    //
    // Monospace is functional, not stylistic: timestamps, status codes and byte counts are
    // read as columns, and a proportional face destroys the alignment that makes a dense list
    // scannable. It applies to data only — chrome stays on the system family.

    static let rowTimestamp   = Font.system(size: 11, weight: .regular, design: .monospaced)
    static let rowPrimary     = Font.system(size: 12.5, weight: .regular, design: .monospaced)
    static let rowPrimaryBold = Font.system(size: 12.5, weight: .semibold, design: .monospaced)
    static let rowStatus      = Font.system(size: 12, weight: .semibold, design: .monospaced)
    static let typeChip       = Font.system(size: 10, weight: .bold, design: .monospaced)
    static let droppedMarker  = Font.system(size: 10, weight: .regular, design: .monospaced)

    static let panelHeader    = Font.system(size: 13, weight: .semibold)
    static let panelCount     = Font.system(size: 13, weight: .regular, design: .monospaced)
    static let chipLabel      = Font.system(size: 13, weight: .regular)
    static let pageTitle      = Font.system(size: 18, weight: .semibold)
    static let searchField    = Font.system(size: 14, weight: .regular)
    static let emptyState     = Font.system(size: 14, weight: .regular)
    static let sectionHeader  = Font.system(size: 11.5, weight: .bold, design: .monospaced)
    static let detailKeyValue = Font.system(size: 12, weight: .regular, design: .monospaced)
    static let bodyBlock      = Font.system(size: 11.5, weight: .regular, design: .monospaced)
    static let beaconCount    = Font.system(size: 17, weight: .bold, design: .monospaced)
    static let beaconStatus   = Font.system(size: 11, weight: .regular, design: .monospaced)

    // MARK: - Geometry

    static let rowHeight: CGFloat = 36
    static let rowHorizontalPadding: CGFloat = 12
    static let rowIndentedLeading: CGFloat = 26
    /// Wide enough for HH:mm:ss.SSS at 11pt monospace. The spec's 66 was an Android sp
    /// value; at iOS point sizes it wraps the timestamp onto a second line.
    static let timestampColumnWidth: CGFloat = 84
    static let typeChipWidth: CGFloat = 50
    static let columnGap: CGFloat = 7
    static let beaconSize: CGFloat = 60
    static let panelDefaultHeightFraction: CGFloat = 0.36
    static let panelMinHeightFraction: CGFloat = 0.20
    static let panelMaxHeightFraction: CGFloat = 0.75

    // MARK: - Helpers

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(networkLogHex: dark) : UIColor(networkLogHex: light)
        })
    }
}

private extension UIColor {
    convenience init(networkLogHex hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
