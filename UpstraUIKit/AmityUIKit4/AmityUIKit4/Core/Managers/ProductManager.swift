//
//  ProductManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/12/26.
//

import AmitySDK

class ProductManager {
    let repository = AmityProductRepository()
    
    func searchProducts(_ queryOptions: AmityProductQueryOptions) -> AmityCollection<AmityProduct> {
        return repository.searchProducts(options: queryOptions)
    }
}
