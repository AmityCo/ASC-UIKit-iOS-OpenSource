//
//  ExpandableTextEditorView.swift
//  AmityUIKit4
//
//  Created by Nishan on 22/2/2567 BE.
//

import SwiftUI

@available(iOS 15.0, *)
extension FocusableTextEditorView: AmityViewBuildable {
    public func placeholder(_ value: String) -> Self {
        mutating(keyPath: \.placeholder, value: value)
    }
    
    public func font(_ value: Font) -> Self {
        mutating(keyPath: \.font, value: value)
    }
    
    public func maxCharCount(_ value: Int) -> Self {
        mutating(keyPath: \.maxCharCount, value: value)
    }
}
    

@available(iOS 15.0, *)
struct FocusableTextEditorView: View {
    @FocusState private var internalFocusState: Bool
    @Binding var externalFocusState: Bool
    @Binding var input: String

    private var placeholder: String = ""
    private var font: Font = .body
    private var maxCharCount: Int = 100
    
    init(input: Binding<String>, focus: Binding<Bool> = .constant(false)) {
        self._input = input
        self._externalFocusState = focus
    }
    
    var body: some View {
        ExpandableTextEditorView(isTextEditorFocused: .constant(internalFocusState), input: $input)
            .placeholder(placeholder)
            .font(font)
            .maxCharCount(maxCharCount)
            .focused($internalFocusState)
            .onChange(of: internalFocusState) { newValue in
                externalFocusState = newValue
            }
            .onChange(of: externalFocusState) { newValue in
                if newValue != internalFocusState {
                    internalFocusState = newValue
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    internalFocusState = externalFocusState
                }
            }
    }
}

extension ExpandableTextEditorView: AmityViewBuildable {
    public func placeholder(_ value: String) -> Self {
        mutating(keyPath: \.placeholder, value: value)
    }
    
    public func font(_ value: Font) -> Self {
        mutating(keyPath: \.font, value: value)
    }
    
    public func maxCharCount(_ value: Int) -> Self {
        mutating(keyPath: \.maxCharCount, value: value)
    }
}
    

struct ExpandableTextEditorView: View {
    private let config: Configuration = .init()
    @State private var textEditorHeight: CGFloat = 26
    @Binding var isTextEditorFocused: Bool
    @Binding var input: String
    private var placeholder: String = ""
    private var font: Font = .body
    private var maxCharCount: Int = 100
    
    init(isTextEditorFocused: Binding<Bool>, input: Binding<String>) {
        self._isTextEditorFocused = isTextEditorFocused
        self._input = input
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // We need this view to determine the height of the text
            // and expand the editor view vertically.
            Text(input)
                .font(font)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .foregroundColor(.clear)
                .lineLimit(config.expandableLineLimit)
                .background(GeometryReader {
                    Color.clear.preference(key: ViewHeightKey.self, value: $0.frame(in: .local).size.height)
                })
            
            ZStack(alignment: .leading) {
                Text(placeholder)
                    .font(font)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .foregroundColor(Color(hex: config.color.placeholder))
                    .opacity(input.isEmpty ? 1 : 0)
                
                TextEditor(text: $input)
                    .font(font)
                    .frame(height: max(40, textEditorHeight))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .transparentBackground()
                    .foregroundColor(Color(hex: config.color.text))
                    .offset(y: 2)
            }
            .background(Color(hex: isTextEditorFocused ? config.color.editorBackground : "000000")) // Black when idle, editorBackground when focused
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        Color(hex: config.color.idleBorder),
                        lineWidth: 1
                    )
                    .isHidden(isTextEditorFocused, remove: true)
            )
            
        }
        .onChange(of: input) { newValue in
            if newValue.count > maxCharCount {
                ImpactFeedbackGenerator.impactFeedback(style: .medium)
                input = String(newValue.prefix(maxCharCount))
            }
        }
        .onPreferenceChange(ViewHeightKey.self) {
            Log.add(event: .info, "TextEditor height changed to \($0)")
            textEditorHeight = $0
        }
    }
    
    struct Configuration {
        let expandableLineLimit: Int = 5
        
        let color = ColorConfig.init()
        
        struct ColorConfig {
            let editorBackground: String = "292B32" // Dark gray when focused
            let placeholder: String = "A5A9B5"
            let text: String = "FFFFFF"
            let idleBorder: String = "8E8E93" // Gray border color
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
    ExpandableTextEditorView(isTextEditorFocused: .constant(true), input: .constant(""))
        .padding(.horizontal)
}
#endif
