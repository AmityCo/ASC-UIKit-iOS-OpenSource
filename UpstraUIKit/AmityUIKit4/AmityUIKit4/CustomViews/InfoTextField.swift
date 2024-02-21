//
//  InfoTextField.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/23/24.
//

import SwiftUI

struct InfoTextFieldModel {
    var title: String
    var placeholder: String
    var isMandatory: Bool
    var infoMessage: String?
    var errorMessage: String?
    var maxCharCount: Int?
}

struct InfoTextField: View {
    var data: InfoTextFieldModel
    @Binding var text: String
    @Binding var isValid: Bool
    
    @State private var charCount: Int = 0

    
    var body: some View {
        let redColor = Color(UIColor(hex: "#FA4D30"))
        let grayColor = Color(UIColor(hex: "#EBECEF"))
        let textFieldLineColor = isValid ? grayColor : redColor
        let infoTextColor = Color(UIColor(hex: "#898E9E"))
        
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text(data.title)
                    .font(.system(size: 17, weight: .semibold))
                if data.isMandatory {
                    Text(" *")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(redColor)
                }
                
                Spacer()
                if let limitedCharCount = data.maxCharCount {
                    Text("\(charCount)/\(limitedCharCount)")
                        .font(.system(size: 13))
                        .foregroundColor(infoTextColor)
                }
            }
            .padding(.bottom, 20)
            
            TextField(data.placeholder, text: $text)
                .font(.system(size: 15))
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: text) { newText in
                    guard let limitedCharCount = data.maxCharCount else { return }
                    charCount = newText.count
                    if charCount >= limitedCharCount {
                        text = String(newText.prefix(limitedCharCount))
                    }
                }
            Rectangle()
                .frame(height: 1)
                .foregroundColor(textFieldLineColor)
                .padding(.top, 16)
            
            if !(data.infoMessage ?? "").isEmpty || !(data.errorMessage ?? "").isEmpty && !isValid {
                Text(isValid ? (data.infoMessage ?? "") : (data.errorMessage ?? data.infoMessage ?? ""))
                    .foregroundColor(isValid ? infoTextColor : redColor)
                    .font(.system(size: 13))
                    .padding(.top, 8)
            }
        }
        .padding(EdgeInsets(top: 24, leading: 16, bottom: 0, trailing: 16))
    }
}


fileprivate struct PreviewView: View {
    @State var text: String = ""
    @State var isValid: Bool = true
    
    var body: some View {
        InfoTextField(data: InfoTextFieldModel(title: "Title", placeholder: "Text Field", isMandatory: true, infoMessage: "Info message is here", errorMessage: "Error message is here", maxCharCount: 20), text: $text, isValid: $isValid)
    }
}

#if DEBUG
#Preview {
    PreviewView()
}
#endif
