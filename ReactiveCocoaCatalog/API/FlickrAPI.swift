//
//  FlickrAPI.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-18.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Foundation
import ReactiveSwift
import APIKit
import Argo
import Curry
import Runes

// MARK: FlickrAPI

struct FlickrAPI {}

// MARK: FlickrRequest

protocol FlickrRequest: Request {}

extension FlickrRequest
{
    var baseURL: URL
    {
        return URL(string: "https://api.flickr.com/services/rest")!
    }
}

/// - Warning: CAN NOT be `extension Request` with error "Segmentation fault: 11".
extension FlickrRequest where Response: Sequence, Response.Iterator.Element: Decodable, Response.Iterator.Element.DecodedType == Response.Iterator.Element
{
    /// Automatic decoding (array).
    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> [Response.Iterator.Element]
    {
        return try decode(object).dematerialize()
    }
}

// MARK: PhotosSearch

extension FlickrAPI
{
    /// - SeeAlso: [Flickr Api Explorer - flickr.photos.search](https://www.flickr.com/services/api/explore/flickr.photos.search)
    struct PhotosSearchRequest: FlickrRequest, PaginationRequest
    {
        typealias Response = PhotosSearchResponse

        let tags: [String]
        let page: Int

        var method: HTTPMethod
        {
            return .get
        }

        var path: String
        {
            return "/" // "/users"
        }

        var queryParameters: [String : Any]?
        {
            return [
                "tags": self.tags,
                "page": self.page,
                "method": "flickr.photos.search",
                "api_key": String(data: Data(base64Encoded: "MTViOTBlYTA0ODQ3YjJlMjg1OTkwMzNmN2NlYzRiMzU=", options: .ignoreUnknownCharacters)!, encoding: .utf8)!,
                "format": "json",
                "nojsoncallback": 1
            ]
        }

        init(tags: [String], page: Int = 1)
        {
            self.tags = tags
            self.page = page
        }

        func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response
        {
            return try decode(object).dematerialize()
        }

        func requestWithPage(_ page: Int) -> PhotosSearchRequest
        {
            return PhotosSearchRequest(tags: self.tags, page: page)
        }
    }

    /// - Note: Generic type nested in struct is not allowed.
    struct PhotosSearchResponse: Decodable, PaginationResponseType
    {
        let items: [Photo]

        let previousPage: Int?
        let nextPage: Int?

        static func decode(_ j: JSON) -> Decoded<PhotosSearchResponse>
        {
            return curry(PhotosSearchResponse.init)
                <^> j <|| ["photos", "photo"]
                <*> ({ (p: Int) in max(p - 1, 1) }
                    <^> (j <| ["photos", "page"]))
                <*> (curry { (p: Int, ps: Int) in min(p + 1, ps) }
                    <^> (j <| ["photos", "page"])
                    <*> (j <| ["photos", "pages"]))
        }
    }

    struct Photo: Decodable, CustomStringConvertible
    {
        let farmId: Int
        let serverId: String
        let photoId: String
        let secret: String

        let title: String

        static func decode(_ j: JSON) -> Decoded<Photo>
        {
            return curry(Photo.init)
                <^> j <| "farm"
                <*> j <| "server"
                <*> j <| "id"
                <*> j <| "secret"
                <*> j <| "title"
        }

        var description: String
        {
            return "Photo(\(imageURL), title: \(title))"
        }

        ///
        /// - SeeAlso:
        /// [Photo Source URLs](https://www.flickr.com/services/api/misc.urls.html)
        ///
        /// - Example:
        ///   - https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}.jpg
        ///   - https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}_[mstzb].jpg
        ///   - https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{o-secret}_o.(jpg|gif|png)
        ///
        var imageURL: URL
        {
            return URL(string: "https://farm\(farmId).staticflickr.com/\(serverId)/\(photoId)_\(secret)_m.jpg")!
        }
    }
}
