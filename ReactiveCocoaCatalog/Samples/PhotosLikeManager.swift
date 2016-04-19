//
//  PhotosLikeManager.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-18.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Foundation
import Result
import ReactiveCocoa

/// Singleton class for on-memory "likes" persistence.
final class PhotosLikeManager
{
    // Singleton.
    static let likes = PhotosLikeManager()

    private var _likes: [NSURL : MutableProperty<Like>] = [:]

    subscript(url: NSURL) -> MutableProperty<Like>
    {
        if let property = self._likes[url] {
            return property
        }
        else {
            let property = MutableProperty<Like>(.None)
            self._likes[url] = property
            return property
        }
    }

    private init() {}
}

enum Like: String
{
    case None = "☆"
    case Liked = "★"

    var detailText: String
    {
        switch self {
            case .None: return "☆ Like?"
            case .Liked: return "★ Liked!"
        }
    }

    var inverse: Like
    {
        switch self {
            case .None: return .Liked
            case .Liked: return .None
        }
    }
}
