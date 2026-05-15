//
//  PollDuration.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 17/10/2567 BE.
//

import SwiftUI

enum PollDuration: Identifiable, Equatable {
    case day1
    case day3
    case day7
    case day14
    case day30
    case custom(date: Date)
    
    var id: String {
        switch self {
        case .custom(let date):
            return "custom-\(date)"
        default:
            return value
        }
    }
    
    var value: String {
        switch self {
        case .day1:
            return AmityLocalizedStringSet.Social.pollDurationSingularDay.localized(arguments: unit)
        case .day3, .day7, .day14, .day30:
            return AmityLocalizedStringSet.Social.pollDurationPluralDays.localized(arguments: unit)
        case .custom(let date):
            return AmityLocalizedStringSet.Social.pollEndsOnLabel.localizedString + " " + Formatters.pollDurationDateString(from: date)
        }
    }
    
    var isCustomDate: Bool {
        if case .custom(_) = self {
            return true
        }
        return false
    }
    
    var unit: Int {
        switch self {
        case .day1:
            return 1
        case .day3:
            return 3
        case .day7:
            return 7
        case .day14:
            return 14
        case .day30:
            return 30
        case .custom(_):
            return 0
        }
    }
}

struct PollDurationSelectionView: View {
    
    @Binding var duration: PollDuration
    @Binding var isVisible: Bool
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @State private var selectedDate = Date()
    @State private var selectDateAndTime = false
    @State private var selection = 0
    @State private var after30Days: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date() // Today + 30 days
    
    var options: [PollDuration] = [.day1, .day3, .day7, .day14, .day30]
    
    var body: some View {
        VStack {
            if selectDateAndTime {
                calendarView
                    .scaleEffect(1)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)).combined(with: .opacity))
            } else {
                optionView
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)).combined(with: .opacity))
            }
        }
        .clipped()
    }
    
    @ViewBuilder
    var optionView: some View {
        VStack {
            ForEach(options) { item in
                OptionButton(title: item.value, isSelected: item == duration, onTap: {
                    self.duration = item
                    self.isVisible = false
                })
            }
            
            Button(action: {
                withAnimation {
                    selectDateAndTime.toggle()
                }
            }, label: {
                HStack {
                    Text(AmityLocalizedStringSet.Social.pollDurationPickDateAndTime.localizedString)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .padding(.trailing, 2)
                }
                .contentShape(Rectangle())
            })
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.bottom, 64)
        }
        .padding(.horizontal, 16)
        .padding(.vertical)
    }
    
    @ViewBuilder
    var calendarView: some View {
        VStack(spacing: 0) {
            AmityNavigationBar(title: AmityLocalizedStringSet.Social.pollEndsOnLabel.localizedString) {
                Button {
                    withAnimation {
                        selectDateAndTime.toggle()
                    }
                } label: {
                    Image(AmityIcon.backIcon.imageResource)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 20)
                }
                
            } trailing: {
                Button {
                    self.duration = .custom(date: selectedDate)
                    self.isVisible = false
                } label: {
                    Text(AmityLocalizedStringSet.Social.pollDurationDoneButton.localizedString)
                }
            }
            
            Divider()
            
            let initialDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            DatePicker(selection: $selectedDate, in: initialDate...after30Days, displayedComponents: [.date, .hourAndMinute]) {
                EmptyView()
            }
            .labelsHidden()
            .datePickerStyle(.graphical)
            .padding(.bottom, 32)
            .padding(.horizontal)
        }
    }
}

struct OptionButton: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            onTap()
        }, label: {
            HStack {
                Text(title)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(lineWidth: 2.0)
                        .fill(.gray)
                        .frame(width: 16, height: 16)
                        .opacity(isSelected ? 0 : 1)
                    
                    Image(AmityIcon.pollRadioIcon.imageResource)
                        .frame(width: 22, height: 22)
                        .opacity(isSelected ? 1 : 0)
                }
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        })
    }
}

class Formatters {
    
    /// Date-only formatter used together with `pollTimeFormatter` to produce a
    /// localized "{date} at {time}" string (see `pollDurationDateString(from:)`).
    static var pollDateOnlyFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "MMM d"
        return dateFormatter
    }()

    /// Returns a localized "{date} at {time}" string for a poll end date
    /// (e.g. "Sep 24 at 9:41 AM" in English, "ก.ย. 24 เวลา 9:41 ก่อนเที่ยง" in Thai).
    /// The connector word ("at") is sourced from `amity_social_poll_date_time_format`
    /// instead of being hardcoded into the format string.
    static func pollDurationDateString(from date: Date) -> String {
        let dateString = pollDateOnlyFormatter.string(from: date)
        let timeString = pollTimeFormatter.string(from: date)
        return AmityLocalizedStringSet.Social.pollDateTimeFormat.localized(arguments: dateString, timeString)
    }

    /// 12-hour time formatter with AM/PM (e.g. "9:41 AM" in English, "9:41
    /// ก่อนเที่ยง" in Thai). The AM/PM markers are sourced from
    /// `amity_common_time_am` / `amity_common_time_pm` instead of CLDR — iOS's
    /// `DateFormatter` ignores the `a` pattern width and always returns the
    /// abbreviated CLDR form (Latin "AM"/"PM" for many locales), so we override
    /// `amSymbol` / `pmSymbol` with our own localized strings.
    static var pollTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = AmityLocalizedStringSet.General.timeAm.localizedString
        dateFormatter.pmSymbol = AmityLocalizedStringSet.General.timePm.localizedString
        return dateFormatter
    }()
    
    static var countFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Date-only formatter used together with `eventTimeFormatter` to produce a
    /// localized "{date} at {time}" string (see `eventStartEndDateString(from:)`).
    static var eventDateOnlyFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "d MMM yyyy"
        return dateFormatter
    }()

    /// Returns a localized "{date} at {time}" string (e.g. "13 May 2026 at 14:30"
    /// in English, "13 พ.ค. 2569 เวลา 14:30" in Thai). The connector word ("at")
    /// is sourced from `amity_social_event_date_time_format` instead of being
    /// hardcoded into the format string.
    static func eventStartEndDateString(from date: Date) -> String {
        let dateString = eventDateOnlyFormatter.string(from: date)
        let timeString = eventTimeFormatter.string(from: date)
        return AmityLocalizedStringSet.Social.eventDateTimeFormat.localized(arguments: dateString, timeString)
    }

    static var eventTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "HH:mm" // 24 Sep at 9:41 AM
        return dateFormatter
    }()
    
    static var eventDateAndTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "d MMM yyyy, HH:mm" // 24 Sep at 9:41 AM
        return dateFormatter
    }()
 }
