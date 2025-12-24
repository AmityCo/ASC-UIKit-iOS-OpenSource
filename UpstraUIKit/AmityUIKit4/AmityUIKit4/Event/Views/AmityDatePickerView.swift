//
//  AmityDatePickerView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 14/10/25.
//

import SwiftUI

struct AmityDatePickerView: View {
    
    @EnvironmentObject
    var viewConfig: AmityViewConfigController
    
    @Environment(\.presentationMode)
    var presentationMode
    
    let title: String
    let selection: Date? // current selection
    let startDate: Date? // initial date for date picker range
    var onSelection: (Date) -> Void

    @State private var selectedDate: Date = Date()
    @State private var after30Days: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date() // Today + 30 days
    let initialDate: Date
    
    init(title: String, selection: Date?, startDate: Date? = nil, onSelection: @escaping (Date) -> Void) {
        self.title = title
        self.selection = selection
        self.startDate = startDate
        self.onSelection = onSelection
        self.initialDate = self.startDate ?? Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        self._selectedDate = State(initialValue: selection ?? Date())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AmityNavigationBar(title: title) {
                Button {
                    presentationMode.wrappedValue.dismiss()
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
                    onSelection(selectedDate)
                    
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text(AmityLocalizedStringSet.Social.pollDurationDoneButton.localizedString)
                        .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                }
            }
            .navigationBarPadding()
            
            Divider()
            
            DatePicker(selection: $selectedDate, in: initialDate..., displayedComponents: [.date, .hourAndMinute]) {
                EmptyView()
            }
            .datePickerStyle(.graphical)
            .frame(minHeight: 430)
            .preferredColorScheme(.light)
            
            Spacer()
        }
        .padding(.vertical, 16)
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
    }
}
