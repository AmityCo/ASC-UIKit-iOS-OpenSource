//
//  Framework.swift
//  AmityUIKitLiveStream
//
//  Created by Nishan Niraula on 28/2/25.
//

import SwiftUI

class Framework {
    static var bundle: Bundle {
        return Bundle(for: self)
    }
}

protocol ImageResourceProvider: RawRepresentable {
    
    var imageResource: ImageResource { get }
}

extension ImageResourceProvider where Self.RawValue == String {
    
    var imageResource: ImageResource {
        ImageResource(name: self.rawValue, bundle: Framework.bundle)
    }
}
