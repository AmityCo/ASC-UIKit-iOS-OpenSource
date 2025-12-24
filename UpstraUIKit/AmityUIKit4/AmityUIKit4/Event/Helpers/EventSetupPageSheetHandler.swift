//
//  EventSetupPageSheetHandler.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 15/10/25.
//

import SwiftUI

class EventSetupPageSheetHandler: ObservableObject {
    
    @Published var current: Route = .none
    @Published var isSheetEnabled: Bool = false
    
    enum Route {
        case timezone(onSelection: (TimeZone) -> Void)
        case location(current: EventLocation?, onSelection: (EventLocation) -> Void)
        case startDate(current: Date, onSelection: (Date) -> Void)
        case endDate(current: Date, startDate: Date, onSelection: (Date) -> Void)
        case none
    }
    
    func showSheet(for destination: Route) {
        current = destination
        
        switch current {
        case .none:
            isSheetEnabled = false
        default:
            isSheetEnabled = true
        }
    }
    
    func dismissSheet() {
        showSheet(for: .none)
    }
    
    @ViewBuilder
    func getDestination() -> some View {
        
        switch current {
        case .timezone(let onSelection):
            if #available(iOS 16.0, *) {
                AmityTimezoneListView { timezone in
                    onSelection(timezone)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .preferredColorScheme(.light)

            } else {
                AmityTimezoneListView { timezone in
                    onSelection(timezone)
                }
                .preferredColorScheme(.light)
            }
        case .location(let current, let onSelection):
            if #available(iOS 16.0, *) {
                AmityEventLocationView(selection: current, onSaveAction: { location in
                    onSelection(location)
                })
                    .presentationDragIndicator(.automatic)
            } else {
                AmityEventLocationView(selection: current) { location in
                    onSelection(location)
                }
            }
        case .startDate(let current, let onSelection):
            if #available(iOS 16.0, *) {
                AmityDatePickerView(title: "Starts on", selection: current, onSelection: { selectedDate in
                    onSelection(selectedDate)
                })
                .presentationDetents([.height(530), .height(550)])
                .presentationDragIndicator(.automatic)
            } else {
                AmityDatePickerView(title: "Starts on", selection: current, onSelection: { selectedDate in
                    onSelection(selectedDate)
                })
            }
        case .endDate(let current, let startDate, let onSelection):
            if #available(iOS 16.0, *) {
                AmityDatePickerView(title: "Ends on", selection: current, startDate: startDate, onSelection: { selectedDate in
                    onSelection(selectedDate)
                })
                .presentationDetents([.height(530), .height(550)])
                .presentationDragIndicator(.automatic)
            } else {
                AmityDatePickerView(title: "Ends on", selection: current, startDate: startDate, onSelection: { selectedDate in
                    onSelection(selectedDate)
                })
            }
        case .none:
            Text("Oops! You should not be seeing this screen.\nPlease report to our team if you see this screen")
        }
    }
}
