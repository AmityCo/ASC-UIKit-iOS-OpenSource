//
//  AmityViewIdentifiable.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/21/23.
//

import Foundation

// MARK: AmityPageIdentifiable Protocol

public protocol AmityPageIdentifiable: Identifiable {
    associatedtype ID = PageId
}

extension AmityPageIdentifiable {
    var configId: String {
        let pageId = (id as? PageId)?.rawValue ?? "*"
        return "\(pageId)/*/*"
    }
}

// MARK: AmityComponentIdentifiable Protocol

public protocol AmityComponentIdentifiable: Identifiable {
    associatedtype ID = ComponentId
    
    var pageId: PageId? { get set }
}

extension AmityComponentIdentifiable {
    var configId: String {
        let pageId = pageId?.rawValue ?? "*"
        let componentId = (id as? ComponentId)?.rawValue ?? "*"
        return "\(pageId)/\(componentId)/*"
    }
}

// MARK: AmityElementIdentifiable Protocol

public protocol AmityElementIdentifiable: Identifiable {
    associatedtype ID = ElementId
    
    var pageId: PageId? { get set }
    var componentId: ComponentId? { get set }
}

extension AmityElementIdentifiable {
    var configId: String {
        let pageId = pageId?.rawValue ?? "*"
        let componentId = componentId?.rawValue ?? "*"
        let elementId = (id as? ElementId)?.rawValue ?? "*"
        return "\(pageId)/\(componentId)/\(elementId)"
    }
}
