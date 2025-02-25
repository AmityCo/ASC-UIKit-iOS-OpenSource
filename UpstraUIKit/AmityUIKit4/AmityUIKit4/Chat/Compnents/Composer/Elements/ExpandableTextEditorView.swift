//
//  ExpandableTextEditorView.swift
//  AmityUIKit4
//
//  Created by Nishan on 22/2/2567 BE.
//

import SwiftUI

struct ExpandableTextEditorView: View {
    
    private let config: Configuration = .init()
    @State
    private var textEditorHeight : CGFloat = 24

    @Binding var input: String
    let placeholder: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            // We need this view to determine the height of the text
            // and expand the editor view vertically.
            Text(input)
                .font(.body)
                .foregroundColor(.clear)
                .padding(10)
                .lineLimit(config.expandableLineLimit)
                .background(GeometryReader {
                    Color.clear.preference(key: ViewHeightKey.self, value: $0.frame(in: .local).size.height)
                })
            
            ZStack(alignment: .leading) {
                Text(placeholder)
                    .padding(.horizontal, 16)
                    .foregroundColor(Color(hex: config.color.placeholder))
                    .opacity(input.isEmpty ? 1 : 0)
                
                // Actual Text Editor
                TextEditor(text: $input)
                    .font(.body)
                    .frame(height: max(40, textEditorHeight))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .transparentBackground()
                    .foregroundColor(Color(hex: config.color.text))
                    
            }
            .background(Color(UIColor(hex: config.color.editorBackground)))
            .cornerRadius(24)
            
        }.onPreferenceChange(ViewHeightKey.self) {
            textEditorHeight = $0
        }
    }
    
    struct Configuration {
        let expandableLineLimit: Int = 5
        
        let color = ColorConfig.init()
        
        struct ColorConfig {
            let editorBackground: String = "292B32"
            let placeholder: String = "A5A9B5"
            let text: String = "FFFFFF"
        }
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = value + nextValue()
    }
}

#if DEBUG
#Preview {
    ExpandableTextEditorView(input: .constant(""), placeholder: "Write a message")
        .padding(.horizontal)
}
#endif
