//
//  PostMediaCap.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/10/26.
//

import Foundation

/// The maximum number of image or video attachments on a single post.
///
/// Defined once and read everywhere it is enforced. It was previously duplicated across six sites in
/// two components that each carry a `#warning` about being copies of one another.
enum PostMediaCap {
    static let maximum = 10
}
