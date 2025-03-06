//
//  PluralWords.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 28/2/25.
//

// Use localized stringsdict later on
class WordsGrammar {
    
    enum StringSet {
        case reply
        
        var singular: String {
            switch self {
            case .reply:
                return "reply"
            }
        }
        
        var plural: String {
            switch self {
            case .reply:
                return "replies"
            }
        }
    }
    
    var value: String
    
    init(count: Int, singular: String, plural: String) {
        if count > 1 {
            value = plural
        } else {
            value = singular
        }
    }
    
    init(count: Int, set: StringSet) {
        if count > 1 {
            value = set.plural
        } else {
            value = set.singular
        }
    }
}
