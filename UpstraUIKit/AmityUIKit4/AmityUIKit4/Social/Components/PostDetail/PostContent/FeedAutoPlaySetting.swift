//
//  FeedAutoPlaySetting.swift
//  AmityUIKit4
//

import Combine
import Foundation
import Network
import SwiftUI

/// When feed videos auto-play, as the member chose it in the own-profile menu.
enum FeedAutoPlayPreference: String, CaseIterable {
    case wifiAndData
    case wifiOnly
    case never

    var accessibilityID: String {
        switch self {
        case .wifiAndData:
            return AccessibilityID.Social.AutoPlaySetting.wifiAndData
        case .wifiOnly:
            return AccessibilityID.Social.AutoPlaySetting.wifiOnly
        case .never:
            return AccessibilityID.Social.AutoPlaySetting.never
        }
    }

    var title: String {
        switch self {
        case .wifiAndData:
            return AmityLocalizedStringSet.Social.autoPlaySettingWifiAndData.localizedString
        case .wifiOnly:
            return AmityLocalizedStringSet.Social.autoPlaySettingWifiOnly.localizedString
        case .never:
            return AmityLocalizedStringSet.Social.autoPlaySettingNever.localizedString
        }
    }
}

/// The member's auto-play choice and the connection it depends on.
///
/// The choice is saved on the device, not per user, so it carries over to whoever logs in next; with nothing
/// saved it is Wi-Fi and mobile data. Feeds auto-play only while the choice allows the current connection,
/// the device is online and Low Data Mode is off. The network switch (`FeedAutoPlaySwitch`) still overrides it.
@MainActor
final class FeedAutoPlaySetting: ObservableObject {

    static let shared = FeedAutoPlaySetting()

    @Published private(set) var preference: FeedAutoPlayPreference
    @Published private(set) var isOnWiFi = true
    @Published private(set) var isOnline = true
    /// iOS Low Data Mode, on Wi-Fi or on mobile data.
    @Published private(set) var isLowDataMode = false

    private static let preferenceKey = "amity_feed_autoplay_preference"
    private let monitor = NWPathMonitor()

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.preferenceKey)
        preference = saved.flatMap(FeedAutoPlayPreference.init(rawValue:)) ?? .wifiAndData

        monitor.pathUpdateHandler = { [weak self] path in
            let isOnline = path.status == .satisfied
            let isOnWiFi = path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet)
            let isLowDataMode = path.isConstrained
            Task { @MainActor in
                guard let self else { return }
                if self.isOnline != isOnline { self.isOnline = isOnline }
                if self.isOnWiFi != isOnWiFi { self.isOnWiFi = isOnWiFi }
                if self.isLowDataMode != isLowDataMode { self.isLowDataMode = isLowDataMode }
            }
        }
        monitor.start(queue: DispatchQueue(label: "co.amity.feedAutoPlay.network"))
    }

    func setPreference(_ preference: FeedAutoPlayPreference) {
        self.preference = preference
        UserDefaults.standard.set(preference.rawValue, forKey: Self.preferenceKey)
    }

    /// Emits whether the choice and the connection allow auto-play, each time that changes.
    var allowsAutoPlayPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest4($preference, $isOnWiFi, $isOnline, $isLowDataMode)
            .map { preference, isOnWiFi, isOnline, isLowDataMode in
                guard isOnline, !isLowDataMode else { return false }
                switch preference {
                case .wifiAndData:
                    return true
                case .wifiOnly:
                    return isOnWiFi
                case .never:
                    return false
                }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

/// The auto-play setting sheet, opened from the own-profile menu's Autoplay in feed row (the same name as on
/// Android): Wi-Fi and mobile data, Wi-Fi only, Never. A choice is saved on tap and closes the sheet, like the
/// post filter; it has no config ID.
struct AmityFeedAutoPlaySettingSheet: View {
    @ObservedObject private var setting = FeedAutoPlaySetting.shared
    /// Called after a choice is saved, to close the sheet.
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach([FeedAutoPlayPreference.wifiAndData, .wifiOnly, .never], id: \.self) { preference in
                BottomSheetRadioItemView(isSelected: setting.preference == preference, text: preference.title)
                    .onTapGesture {
                        setting.setPreference(preference)
                        onSelect()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(setting.preference == preference ? [.isButton, .isSelected] : .isButton)
                    .accessibilityIdentifier(preference.accessibilityID)
                    .accessibilityValue(setting.preference == preference ? "selected" : "") // l10n:ok test value
            }
        }
        .padding(.bottom, 32)
    }
}
