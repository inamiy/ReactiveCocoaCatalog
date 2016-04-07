//
//  GitHubAPI.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import Foundation
import Curry
import ReactiveCocoa
import APIKit
import Argo
import WebLinking

// MARK: GitHubAPI

struct GitHubAPI {}

// MARK: GitHubRequestType

protocol GitHubRequestType: RequestType {}

extension GitHubRequestType
{
    var baseURL: NSURL
    {
        return NSURL(string: "https://api.github.com")!
    }
}

/// - Note: Can be `extension RequestType`.
extension GitHubRequestType where Response: Decodable, Response.DecodedType == Response
{
    /// Automatic decoding.
    func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) -> Response?
    {
        return decode(object)
    }
}

/// - Warning: CAN NOT be `extension RequestType` with error "Segmentation fault: 11".
extension GitHubRequestType where Response: SequenceType, Response.Generator.Element: Decodable, Response.Generator.Element.DecodedType == Response.Generator.Element
{
    /// Automatic decoding (array).
    func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) -> [Response.Generator.Element]?
    {
        return decode(object)
    }
}

extension GitHubRequestType where Response: PaginationResponseType, Response.Item: Decodable, Response.Item.DecodedType == Response.Item
{
    /// Automatic decoding (for PaginationResponse).
    func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) -> Response?
    {
        var previousPage: Int?
        if let previousURI = URLResponse.findLink(relation: "prev")?.uri,
            let queryItems = NSURLComponents(string: previousURI)?.queryItems {
                previousPage = queryItems
                    .filter { $0.name == "page" }
                    .first
                    .flatMap { $0.value }
                    .flatMap { Int($0) }
        }

        var nextPage: Int?
        if let nextURI = URLResponse.findLink(relation: "next")?.uri,
            let queryItems = NSURLComponents(string: nextURI)?.queryItems {
                nextPage = queryItems
                    .filter { $0.name == "page" }
                    .first
                    .flatMap { $0.value }
                    .flatMap { Int($0) }
        }

        let items: [Response.Item]? = decodeWithRootKey("items", object)

        return items.map { Response(items: $0, previousPage: previousPage, nextPage: nextPage) }
    }
}

// MARK: User

extension GitHubAPI
{
    struct UsersRequest: GitHubRequestType
    {
        typealias Response = [User]

        let since: Int

        var method: HTTPMethod
        {
            return .GET
        }

        var path: String
        {
            return "/users"
        }

        var parameters: [String : AnyObject]
        {
            return ["since" : self.since]
        }

        init(since: Int)
        {
            self.since = since
        }
    }

    struct User: Decodable
    {
        let login: String
        let avatarURL: NSURL

        static func decode(j: JSON) -> Decoded<User>
        {
            return curry(User.init)
                <^> j <| "login"
                <*> (j <| "avatar_url").flatMap { .fromOptional(NSURL(string: $0)) }
        }
    }
}

// MARK: Repository

extension GitHubAPI
{
    struct SearchRepositoriesRequest: GitHubRequestType, PaginationRequestType
    {
        typealias Response = PaginationResponse<Repository>

        let query: String
        let page: Int

        init(query: String, page: Int = 1)
        {
            self.query = query
            self.page = page
        }

        // MARK: RequestType

        var method: HTTPMethod
        {
            return .GET
        }

        var path: String
        {
            return "/search/repositories"
        }

        var parameters: [String: AnyObject]
        {
            return ["q": query, "page": page]
        }

        // MARK: PaginationRequestType

        func requestWithPage(page: Int) -> SearchRepositoriesRequest
        {
            return SearchRepositoriesRequest(query: query, page: page)
        }
    }

    struct Repository: Decodable, CustomStringConvertible
    {
        let id: Int
        let fullName: String
        let stargazersCount: Int

        static func decode(j: JSON) -> Decoded<Repository>
        {
            return curry(Repository.init)
                <^> j <| "id"
                <*> j <| "full_name"
                <*> j <| "stargazers_count"
        }

        var description: String
        {
            return "Repository(id: \(id), name: \(fullName), star: \(stargazersCount))"
        }
    }
}
