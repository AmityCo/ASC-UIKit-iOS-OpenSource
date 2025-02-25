//
//  BottomSheetDragIndicator.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/2/24.
//

import SwiftUI

struct BottomSheetDragIndicator: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .frame(width: 40, height: 6)
            .padding([.top, .bottom], 10)
    }
}
