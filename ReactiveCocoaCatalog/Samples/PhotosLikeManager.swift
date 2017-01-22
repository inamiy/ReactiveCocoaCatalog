//
//  PhotosLikeManager.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-18.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Foundation
import Result
import ReactiveSwift

/// Singleton class for on-memory "likes" persistence.
final class PhotosLikeManager
{
    // Singleton.
    static let likes = PhotosLikeManager()

    private var _likes: [URL : MutableProperty<Like>] = [:]

    subscript(url: URL) -> MutableProperty<Like>
    {
        if let property = self._likes[url] {
            return property
        }
        else {
            let property = MutableProperty<Like>(.none)
            self._likes[url] = property
            return property
        }
    }

    private init() {}
}

enum Like: String
{
    case none = "☆"
    case liked = "★"

    var detailText: String
    {
        switch self {
            case .none: return "☆ Like?"
            case .liked: return "★ Liked!"
        }
    }

    var inverse: Like
    {
        switch self {
            case .none: return .liked
            case .liked: return .none
        }
    }
}
