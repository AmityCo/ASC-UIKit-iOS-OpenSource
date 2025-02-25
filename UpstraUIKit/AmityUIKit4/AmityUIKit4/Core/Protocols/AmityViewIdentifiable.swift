//
//  AmityViewIdentifiable.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/21/23.
//

import Foundation

// MARK: AmityViewIdentifiable Protocol
public protocol AmityViewIdentifiable: Identifiable {}

extension AmityViewIdentifiable {
    public var id: String {
        UUID().uuidString
    }
    
    public func getConfig<T>(pageId: PageId? = nil,
                             componentId: ComponentId? = nil,
                             elementId: ElementId,
                             key: String,
                             of type: T.Type) -> T? {
        let pageId = pageId?.rawValue ?? "*"
        let componentId = componentId?.rawValue ?? "*"
        let configId = "\(pageId)/\(componentId)/\(elementId.rawValue)"
        
        let config = AmityUIKitConfigController.shared.getConfig(configId: configId)
        
        return config[key] as? T
    }
    
}

// MARK: AmityPageIdentifiable Protocol

public protocol AmityPageIdentifiable: AmityViewIdentifiable {
    associatedtype ID = PageId
}

extension AmityPageIdentifiable {
    public var configId: String {
        let pageId = (id as? PageId)?.rawValue ?? "*"
        return "\(pageId)/*/*"
    }
    
    public func getElementConfig<T>(elementId: ElementId, 
                                    key: String,
                                    of type: T.Type) -> T? {
        return getConfig(pageId: id as? PageId,
                         componentId: nil,
                         elementId: elementId,
                         key: key,
                         of: type)
    }
}

// MARK: AmityComponentIdentifiable Protocol

public protocol AmityComponentIdentifiable: AmityViewIdentifiable {
    associatedtype ID = ComponentId
    
    var pageId: PageId? { get set }
}

extension AmityComponentIdentifiable {
    public var configId: String {
        let pageId = pageId?.rawValue ?? "*"
        let componentId = (id as? ComponentId)?.rawValue ?? "*"
        return "\(pageId)/\(componentId)/*"
    }
    
    public func getElementConfig<T>(elementId: ElementId, 
                             key: String,
                             of type: T.Type) -> T? {
        return getConfig(pageId: pageId,
                         componentId: id as? ComponentId,
                         elementId: elementId,
                         key: key,
                         of: type)
    }
}

// MARK: AmityElementIdentifiable Protocol

public protocol AmityElementIdentifiable: AmityViewIdentifiable {
    associatedtype ID = ElementId
    
    var pageId: PageId? { get set }
    var componentId: ComponentId? { get set }
}

extension AmityElementIdentifiable {
    public var configId: String {
        let pageId = pageId?.rawValue ?? "*"
        let componentId = componentId?.rawValue ?? "*"
        let elementId = (id as? ElementId)?.rawValue ?? "*"
        return "\(pageId)/\(componentId)/\(elementId)"
    }
}

protocol UIKitConfigurable {
    var pageId: PageId? { get set }
    var componentId: ComponentId? { get set }
    var elementId: ElementId? { get set }
    var configId: String { get }
        
    func getElementConfig(elementId: ElementId) -> [String: Any]
}

extension UIKitConfigurable {
    
    var configId: String {
        let pageId = pageId?.rawValue ?? "*"
        let componentId = componentId?.rawValue ?? "*"
        let elementId = elementId?.rawValue ?? "*"
        return "\(pageId)/\(componentId)/\(elementId)"
    }
    
    func getElementConfig(elementId: ElementId) -> [String: Any] {
        let pageId = pageId?.rawValue ?? "*"
        let componentId = componentId?.rawValue ?? "*"
        let elementId = elementId.rawValue
        let configId = "\(pageId)/\(componentId)/\(elementId)"
        
        return AmityUIKitConfigController.shared.getConfig(configId: configId)
    }
}
