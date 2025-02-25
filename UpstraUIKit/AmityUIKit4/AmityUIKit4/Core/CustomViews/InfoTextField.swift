//
//  InfoTextField.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/23/24.
//

import SwiftUI

struct InfoTextFieldModel {
    // Title of TextField
    var title: String
    
    // Placeholder of TextField
    var placeholder: String
    
    // If TextField is mandatory and want to show * after title
    var isMandatory: Bool
    
    // If TextField is optional and want to show optional text after title
    var showOptionalTitle: Bool = false
    
    // If TextField needs to show info message under it
    var infoMessage: String?
    
    // If TextField need to show error message if data is not valid.
    // isValid property will decide to show or not the error message.
    var errorMessage: String?
    
    // If TextField need to be expandable
    var isExpandable: Bool = false
    
    // If TextField need to limit maximum character count
    var maxCharCount: Int?
}

extension InfoTextField: AmityViewBuildable {
    // Color that will show if inValid proptery is true
    public func alertColor(_ value: UIColor) -> Self {
        mutating(keyPath: \.alertColor, value: value)
    }
    
    // Color of TextField underline divider
    public func dividerColor(_ value: UIColor) -> Self {
        mutating(keyPath: \.dividerColor, value: value)
    }
    
    // Color of TextField title
    public func titleTextColor(_ value: UIColor) -> Self {
        mutating(keyPath: \.titleTextColor, value: value)
    }
    
    // Color of information text after title e.g. ( Optional )
    public func infoTextColor(_ value: UIColor) -> Self {
        mutating(keyPath: \.infoTextColor, value: value)
    }
    
    // Color of TextField text
    public func textFieldTextColor(_ value: UIColor) -> Self {
        mutating(keyPath: \.textFieldTextColor, value: value)
    }
}

struct InfoTextField: View {
    @Binding var data: InfoTextFieldModel
    @Binding var text: String
    @Binding var isValid: Bool
    
    @State private var charCount: Int = 0
    
    private let titleTextAccessibilityId: String?
    private let textFieldAccessibilityId: String?
    private let descriptionTextAccessibilityId: String?
    private let charCountTextAccessibilityId: String?
    
    private var alertColor: UIColor = UIColor(hex: "#FA4D30")
    private var dividerColor: UIColor = UIColor(hex: "#EBECEF")
    private var titleTextColor: UIColor?
    private var infoTextColor: UIColor = UIColor(hex: "#898E9E")
    private var textFieldTextColor: UIColor = UIColor(hex: "#000000")
    
    init(data: Binding<InfoTextFieldModel>,
         text: Binding<String>,
         isValid: Binding<Bool>,
         titleTextAccessibilityId: String? = nil,
         textFieldAccessibilityId: String? = nil,
         descriptionTextAccessibilityId: String? = nil,
         errorTextAccessibilityId: String? = nil,
         charCountTextAccessibilityId: String? = nil) {
        self._data = data
        self._text = text
        self._isValid = isValid
        
        self.titleTextAccessibilityId = titleTextAccessibilityId
        self.textFieldAccessibilityId = textFieldAccessibilityId
        self.descriptionTextAccessibilityId = descriptionTextAccessibilityId
        self.charCountTextAccessibilityId = charCountTextAccessibilityId
    }

    
    var body: some View {
        let textFieldLineColor = isValid ? dividerColor : alertColor
        
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text(data.title)
                    .applyTextStyle(.titleBold(Color(titleTextColor == nil ? textFieldTextColor : titleTextColor!)))
                    .accessibilityIdentifier(titleTextAccessibilityId ?? "titleTextAccessibilityId")
                
                if data.isMandatory {
                    Text(" *")
                        .applyTextStyle(.titleBold(Color(alertColor)))
                } else {
                    if data.showOptionalTitle {
                        Text(" (Optional)")
                            .applyTextStyle(.caption(Color(infoTextColor)))
                    }
                }
                
                Spacer()
                if let limitedCharCount = data.maxCharCount {
                    Text("\(charCount)/\(limitedCharCount)")
                        .applyTextStyle(.caption(Color(infoTextColor)))
                        .accessibilityIdentifier(charCountTextAccessibilityId ?? "charCountTextAccessibilityId")
                }
            }
            .padding(.bottom, 20)
            
            textField
                .applyTextStyle(.body(Color(textFieldTextColor)))
                .lineLimit(data.isExpandable ? 7 : 1)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: text) { newText in
                    guard let limitedCharCount = data.maxCharCount else { return }
                    charCount = newText.count
                    if charCount >= limitedCharCount {
                        text = String(newText.prefix(limitedCharCount))
                    }
                }
                .onAppear {
                    guard let limitedCharCount = data.maxCharCount else { return }
                    charCount = text.count
                    if charCount >= limitedCharCount {
                        text = String(text.prefix(limitedCharCount))
                    }
                }
                .accessibilityIdentifier(textFieldAccessibilityId ?? "textFieldAccessibilityId")
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(textFieldLineColor))
                .padding(.top, 16)
            
            if !(data.infoMessage ?? "").isEmpty || !(data.errorMessage ?? "").isEmpty && !isValid {
                Text(isValid ? (data.infoMessage ?? "") : (data.errorMessage ?? data.infoMessage ?? ""))
                    .applyTextStyle(.caption(isValid ? Color(infoTextColor) : Color(alertColor)))
                    .padding(.top, 8)
                    .accessibilityIdentifier(descriptionTextAccessibilityId ?? "descriptionTextAccessibilityId")
            }
        }
    }
    
    private var textField: TextField<Text> {
        if #available(iOS 16.0, *) {
            return TextField(data.placeholder, text: $text, axis: .vertical)
        } else {
            return TextField(data.placeholder, text: $text)
        }
    }
}


struct TestInfoTextField: View {
    @State var dataModel = InfoTextFieldModel(title: "Hello", placeholder: "Hello", isMandatory: false, showOptionalTitle: true, isExpandable: true, maxCharCount: 180)
    @State var text: String = ""
    @State var isVaild: Bool = true
    
    var body: some View {
        InfoTextField(data: $dataModel, text: $text, isValid: $isVaild)
    }
}


#if DEBUG
#Preview(body: {
    TestInfoTextField()
})
#endif
