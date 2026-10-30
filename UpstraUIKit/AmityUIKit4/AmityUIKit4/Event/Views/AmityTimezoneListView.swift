//
//  AmityTimezoneListView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 14/10/25.
//

import SwiftUI

struct AmityTimezoneListView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let onSelection: (TimeZone) -> Void
    
    // knownTimeZoneIdentifiers includes legacy aliases (e.g. Europe/Kiev for Europe/Kyiv) that
    // render the same row, so keep one zone per label and prefer its current identifier.
    private let timezones: [TimeZone] = {
        var byLabel: [String: TimeZone] = [:]
        for timezone in TimeZone.knownTimeZoneIdentifiers.compactMap({ TimeZone(identifier: $0) }) {
            let label = TimeZoneFormatter.string(from: timezone)
            if byLabel[label] == nil || TimeZoneFormatter.isCurrentIdentifier(timezone) {
                byLabel[label] = timezone
            }
        }
        return byLabel.values.sorted { tz1, tz2 in
            let offset1 = TimeZoneFormatter.standardSecondsFromGMT(tz1)
            let offset2 = TimeZoneFormatter.standardSecondsFromGMT(tz2)
            if offset1 != offset2 {
                return offset1 < offset2
            }
            return tz1.identifier < tz2.identifier
        }
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                
                Spacer()
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(timezones, id: \.identifier) { timezone in
                        Text(TimeZoneFormatter.string(from: timezone))
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                            .padding(16)
                            .onTapGesture {
                                onSelection(timezone)
                                
                                presentationMode.wrappedValue.dismiss()
                            }
                    }
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).edgesIgnoringSafeArea(.bottom))
    }
    
    func formatTimezone(_ timezone: TimeZone) -> String {
        let seconds = timezone.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds % 3600) / 60
        
        let sign = hours >= 0 ? "+" : ""
        let offset = minutes > 0
        ? String(format: "%@%02d:%02d", sign, hours, minutes)
        : String(format: "%@%02d:00", sign, hours)
        
        // Get a readable name for the timezone
        let name = timezone.localizedName(for: .standard, locale: .current) ?? timezone.identifier
        
        // Get a city from the identifier (e.g., "Asia/Shanghai" -> "Shanghai")
        let city = timezone.identifier.components(separatedBy: "/").last ?? ""
        
        return "(GMT \(offset)) \(name) - \(city)"
    }
}

struct TimeZoneFormatter {

    /// DateFormatter that emits the timezone's *exemplar city* localized for the
    /// current locale (CLDR `VVV` pattern). e.g. "Asia/Bangkok" → "Bangkok" in
    /// English, "กรุงเทพ" in Thai. Splitting the IANA identifier (the previous
    /// approach) always produced the English ASCII city since the identifier is
    /// locale-independent.
    private static let cityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "VVV"
        return formatter
    }()

    /// Exemplar city in English, which uses the same spelling as IANA identifiers.
    private static let englishCityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "VVV"
        return formatter
    }()

    /// Offset without daylight saving time, so it matches the standard name shown
    /// next to it and stays the same all year (same as Android's `rawOffset`).
    static func standardSecondsFromGMT(_ timezone: TimeZone) -> Int {
        timezone.secondsFromGMT() - Int(timezone.daylightSavingTimeOffset())
    }

    static func string(from timezone: TimeZone) -> String {
        let seconds = standardSecondsFromGMT(timezone)
        let hours = seconds / 3600
        let minutes = abs(seconds % 3600) / 60

        let sign = hours >= 0 ? "+" : ""
        let offset = minutes > 0
        ? String(format: "%@%02d:%02d", sign, hours, minutes)
        : String(format: "%@%02d:00", sign, hours)

        // Localized timezone name (e.g. "Indochina Time" / "เวลามาตรฐานอินโดจีน")
        let name = timezone.localizedName(for: .standard, locale: .current) ?? timezone.identifier

        // Localized exemplar city for the timezone (e.g. "Bangkok" / "กรุงเทพ").
        // Falls back to the last identifier component if the formatter returns empty.
        cityFormatter.timeZone = timezone
        let localizedCity = cityFormatter.string(from: Date())
        let city = localizedCity.isEmpty ? (timezone.identifier.components(separatedBy: "/").last ?? "") : localizedCity

        return "(GMT \(offset)) \(name) - \(city)"
    }

    /// True when the identifier ends with its own exemplar city, e.g. "Europe/Kyiv"
    /// but not its legacy alias "Europe/Kiev". Only used to choose between aliases
    /// that render the same row, since many current identifiers don't match their
    /// city spelling (e.g. "America/Sao_Paulo" → "São Paulo").
    static func isCurrentIdentifier(_ timezone: TimeZone) -> Bool {
        englishCityFormatter.timeZone = timezone
        let city = englishCityFormatter.string(from: Date()).replacingOccurrences(of: " ", with: "_")
        return timezone.identifier.hasSuffix("/" + city)
    }
}
