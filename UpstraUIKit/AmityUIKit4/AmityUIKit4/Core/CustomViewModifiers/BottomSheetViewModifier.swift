//
//  BottomSheetViewModifier.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/21/24.
//

import SwiftUI

struct BottomSheetModifier<SheetContent>: ViewModifier where SheetContent: View {
    
    private let height: CGFloat
    private let sheetContent: () -> SheetContent
    private let backgroundColor: Color
    @Binding private var isShowing: Bool
    @State private var offset: CGFloat = 0.0
    @State private var showContentView: Bool = false
    @State private var isSheetPresented: Bool = false
    @State private var backgroundOpacity: CGFloat = 0.4
    
    init(isShowing: Binding<Bool>, height: CGFloat, backgroundColor: Color = .white, sheetContent: @escaping () -> SheetContent) {
        self._isShowing = isShowing
        self.height = height
        self.backgroundColor = backgroundColor
        self.sheetContent = sheetContent
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isShowing) { value in
                if value {
                    withoutAnimation {
                        isSheetPresented = true
                    }
                } else {
                    withAnimation {
                        showContentView = false
                    }
                }
            }
            .onChange(of: showContentView) { value in
                if showContentView == false {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withoutAnimation {
                            isSheetPresented = false
                            isShowing = false
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $isSheetPresented) {
                ZStack(alignment: .bottom) {
                    if showContentView {
                        Color.black
                            .opacity(backgroundOpacity)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation {
                                    showContentView = false
                                }
                            }
                        
                        VStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary)
                                .frame(width: 40, height: 6)
                                .padding(.top, 10)
                                                
                            sheetContent()
                        }
                        .frame(maxWidth: .infinity, maxHeight: height)
                        .background(backgroundColor)
                        .clipShape(RoundedCorner(radius: 16, corners: [.topLeft, .topRight]))
                        .transition(.move(edge: .bottom))
                        .offset(y: offset)
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { gesture in
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        offset = gesture.translation.height > 0 ? gesture.translation.height : 0
                                        updateOpacity(for: offset)
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        if offset > height / 4 {
                                            withAnimation {
                                                showContentView = false
                                            }
                                        }
                                        offset = 0
                                        backgroundOpacity = 0.4
                                    }
                                }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea()
                .background(ClearBackgroundView())
                .animation(.easeInOut(duration: 0.2), value: showContentView)
                .onAppear {
                    withAnimation {
                        showContentView = true
                    }
                }
                .transaction { $0.disablesAnimations = false }
            }
            .transaction { $0.disablesAnimations = true }
    }
    
    private func updateOpacity(for yOffset: CGFloat) {
        let normalizedOffset = max(0, min(abs(yOffset) / 500, 1.0))
        self.backgroundOpacity = Double(0.4 - normalizedOffset)
    }
}


extension View {
    func bottomSheet<SheetContent: View>(isShowing: Binding<Bool>, height: CGFloat, backgroundColor: Color = .white, sheetContent: @escaping () -> SheetContent) -> some View {
        return self.modifier(BottomSheetModifier(isShowing: isShowing, height: height, backgroundColor: backgroundColor, sheetContent: sheetContent))
    }
}
