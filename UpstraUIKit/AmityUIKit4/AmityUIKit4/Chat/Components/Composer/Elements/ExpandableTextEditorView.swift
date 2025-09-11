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
    
    public func lineLimit(_ value: Int) -> Self {
        mutating(keyPath: \.lineLimit, value: value)
    }
    
    public func placeholderColor(_ value: Color) -> Self {
        mutating(keyPath: \.placeholderColor, value: value)
    }
    
    public func textColor(_ value: Color) -> Self {
        mutating(keyPath: \.textColor, value: value)
    }
    
    public func disableNewlines(_ value: Bool = true) -> Self {
        mutating(keyPath: \.disableNewlines, value: value)
    }
    
    public func focusedBackgroundColor(_ value: Color) -> Self {
        mutating(keyPath: \.focusedBackgroundColor, value: value)
    }
    
    public func idleBackgroundColor(_ value: Color) -> Self {
        mutating(keyPath: \.idleBackgroundColor, value: value)
    }
    
    public func borderColor(_ value: Color) -> Self {
        mutating(keyPath: \.borderColor, value: value)
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
    private var lineLimit: Int = 5
    private var placeholderColor: Color = Color(hex: "A5A9B5")
    private var textColor: Color = Color(hex: "FFFFFF")
    private var disableNewlines: Bool = false
    private var focusedBackgroundColor: Color = Color(hex: "292B32")
    private var idleBackgroundColor: Color = Color(hex: "000000")
    private var borderColor: Color = Color(hex: "8E8E93")
    
    init(input: Binding<String>, focus: Binding<Bool> = .constant(false)) {
        self._input = input
        self._externalFocusState = focus
    }
    
    var body: some View {
        ExpandableTextEditorView(isTextEditorFocused: .constant(internalFocusState), input: $input)
            .placeholder(placeholder)
            .font(font)
            .maxCharCount(maxCharCount)
            .lineLimit(lineLimit)
            .placeholderColor(placeholderColor)
            .textColor(textColor)
            .disableNewlines(disableNewlines)
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
            .background(externalFocusState ? focusedBackgroundColor : idleBackgroundColor)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        borderColor,
                        lineWidth: 1
                    )
                    .isHidden(externalFocusState, remove: true)
            )
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
    
    public func lineLimit(_ value: Int) -> Self {
        mutating(keyPath: \.lineLimit, value: value)
    }
    
    public func placeholderColor(_ value: Color) -> Self {
        mutating(keyPath: \.placeholderColor, value: value)
    }
    
    public func textColor(_ value: Color) -> Self {
        mutating(keyPath: \.textColor, value: value)
    }
    
    public func disableNewlines(_ value: Bool = true) -> Self {
        mutating(keyPath: \.disableNewlines, value: value)
    }
}
    

struct ExpandableTextEditorView: View {
    @State private var textEditorHeight: CGFloat = 26
    @Binding var isTextEditorFocused: Bool
    @Binding var input: String
    private var placeholder: String = ""
    private var font: Font = .body
    private var maxCharCount: Int = 100
    private var lineLimit: Int = 5
    private var placeholderColor: Color = Color(hex: "A5A9B5")
    private var textColor: Color = Color(hex: "FFFFFF")
    private var disableNewlines: Bool = false
    
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
                .lineLimit(lineLimit)
                .background(GeometryReader {
                    Color.clear.preference(key: ViewHeightKey.self, value: $0.frame(in: .local).size.height)
                })
            
            ZStack(alignment: .leading) {
                Text(placeholder)
                    .font(font)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .foregroundColor(placeholderColor)
                    .opacity(input.isEmpty ? 1 : 0)
                
                TextEditor(text: $input)
                    .font(font)
                    .frame(height: max(40, textEditorHeight))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .transparentBackground()
                    .foregroundColor(textColor)
                    .offset(y: 2)
            }
        }
        .onChange(of: input) { newValue in
            var processedValue = newValue
            
            // Handle newline filtering if disabled
            if disableNewlines && newValue.contains("\n") {
                processedValue = newValue.replacingOccurrences(of: "\n", with: "")
            }
            
            // Handle character limit
            if processedValue.count > maxCharCount {
                ImpactFeedbackGenerator.impactFeedback(style: .medium)
                processedValue = String(processedValue.prefix(maxCharCount))
            }
            
            // Update input if it was modified
            if processedValue != newValue {
                input = processedValue
            }
        }
        .onPreferenceChange(ViewHeightKey.self) {
            Log.add(event: .info, "TextEditor height changed to \($0)")
            textEditorHeight = $0
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
