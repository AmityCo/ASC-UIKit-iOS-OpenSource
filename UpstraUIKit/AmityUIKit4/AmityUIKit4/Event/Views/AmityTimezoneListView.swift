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
    
    private let timezones = TimeZone.knownTimeZoneIdentifiers.map { identifier in
        TimeZone(identifier: identifier)!
    }.sorted { tz1, tz2 in
        tz1.secondsFromGMT() < tz2.secondsFromGMT()
    }
    
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
    
    static func string(from timezone: TimeZone) -> String {
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
