//
//  PluralWords.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 28/2/25.
//

// NOTE:
// Migrate to localized stringsdict later on
class WordsGrammar {
    
    enum StringSet {
        case reply
        case post
        case request
        case member
        
        var singular: String {
            switch self {
            case .reply:
                return "reply"
            case .post:
                return "post"
            case .request:
                return "request"
            case .member:
                return "member"
            }
        }
        
        var plural: String {
            switch self {
            case .reply:
                return "replies"
            case .post:
                return "posts"
            case .request:
                return "requests"
            case .member:
                return "members"
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
