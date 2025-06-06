//
//  View+Helper.swift
//  SwiftUIPager
//
//  Created by Fernando Moya de Rivas on 19/01/2020.
//  Copyright © 2020 Fernando Moya de Rivas. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension View {

    func frame(size: CGSize) -> some View {
        frame(width: size.width, height: size.height)
    }

    func eraseToAny() -> AnyView {
        AnyView(self)
    }

    func debugBorder(_ color: Color = .red) -> some View {
        self
            .border(color, width: 1)
    }
    
}

