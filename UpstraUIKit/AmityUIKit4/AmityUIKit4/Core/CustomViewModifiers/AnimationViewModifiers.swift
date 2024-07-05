//
//  AnimationViewModifiers.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/21/24.
//

import SwiftUI

struct AnimateViewTransaction: ViewModifier {
    @State private var isViewAppeared: Bool = false
    private let effectId: String
    private let namespace: Namespace.ID
    
    init(effectId: String? = nil, namespace: Namespace.ID? = nil) {
        self.effectId = effectId ?? ""
        self.namespace = namespace ?? Namespace().wrappedValue
    }
    
    func body(content: Content) -> some View {
        Group {
            if isViewAppeared {
                ZStack {
                    content
                    Rectangle()
                        .matchedGeometryEffect(id: effectId, in: namespace)
                }
            }
        }
        .onAppear {
            isViewAppeared = true
        }
        .frame(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        .ignoresSafeArea(.all)
        .animation(.easeIn(duration: 0.25), value: isViewAppeared)
    }
}

extension View {
    func animateViewTransaction(effectId: String? = nil, namespace: Namespace.ID? = nil) -> some View {
        return self.modifier(AnimateViewTransaction(effectId: effectId, namespace: namespace))
    }
}
