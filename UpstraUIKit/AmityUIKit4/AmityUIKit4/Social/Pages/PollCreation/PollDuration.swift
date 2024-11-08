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
            return AmityLocalizedStringSet.Social.pollEndsOnLabel.localizedString + " " + Formatters.pollDurationFormatter.string(from: date)
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
            .padding(.horizontal)
            
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
}

class Formatters {
    
    static var pollDurationFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "MMM d' at 'h:mm a" // 24 Sep at 9:41 AM
        return dateFormatter
    }()
    
    static var countFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}
