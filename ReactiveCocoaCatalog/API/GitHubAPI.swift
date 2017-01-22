//
//  GitHubAPI.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import Foundation
import ReactiveSwift
import APIKit
import Argo
import Curry
import Runes
import WebLinking

// MARK: GitHubAPI

struct GitHubAPI {}

// MARK: GitHubRequest

protocol GitHubRequest: Request {}

extension GitHubRequest
{
    var baseURL: URL
    {
        return URL(string: "https://api.github.com")!
    }
}

/// - Warning: CAN NOT be `extension Request` with error "Segmentation fault: 11".
extension GitHubRequest where Response: Sequence, Response.Iterator.Element: Decodable, Response.Iterator.Element.DecodedType == Response.Iterator.Element
{
    /// Automatic decoding (array).
    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> [Response.Iterator.Element]
    {
        return try decode(object).dematerialize()
    }
}

extension GitHubRequest where Response: PaginationResponseType, Response.Item: Decodable, Response.Item.DecodedType == Response.Item
{
    /// Automatic decoding (for PaginationResponse).
    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response
    {
        var previousPage: Int?
        if let previousURI = urlResponse.findLink(relation: "prev")?.uri,
            let queryItems = URLComponents(string: previousURI)?.queryItems
        {
            previousPage = queryItems
                .filter { $0.name == "page" }
                .first
                .flatMap { $0.value }
                .flatMap { Int($0) }
        }

        var nextPage: Int?
        if let nextURI = urlResponse.findLink(relation: "next")?.uri,
            let queryItems = URLComponents(string: nextURI)?.queryItems
        {
            nextPage = queryItems
                .filter { $0.name == "page" }
                .first
                .flatMap { $0.value }
                .flatMap { Int($0) }
        }

        return try (JSON(object) <|| "items")
            .map { Response(items: $0, previousPage: previousPage, nextPage: nextPage) }
            .dematerialize()
    }
}

// MARK: User

extension GitHubAPI
{
    struct UsersRequest: GitHubRequest
    {
        typealias Response = [User]

        let since: Int

        var method: HTTPMethod
        {
            return .get
        }

        var path: String
        {
            return "/users"
        }

        var queryParameters: [String : Any]?
        {
            return ["since": self.since]
        }

        init(since: Int)
        {
            self.since = since
        }
    }

    struct User: Decodable
    {
        let login: String
        let avatarURL: URL

        static func decode(_ j: JSON) -> Decoded<User>
        {
            return curry(User.init)
                <^> j <| "login"
                <*> (j <| "avatar_url").flatMap { .fromOptional(URL(string: $0)) }
        }
    }
}

// MARK: Repository

extension GitHubAPI
{
    struct SearchRepositoriesRequest: GitHubRequest, PaginationRequest
    {
        typealias Response = PaginationResponse<Repository>

        let query: String
        let page: Int

        init(query: String, page: Int = 1)
        {
            self.query = query
            self.page = page
        }

        // MARK: Request

        var method: HTTPMethod
        {
            return .get
        }

        var path: String
        {
            return "/search/repositories"
        }

        var queryParameters: [String: Any]?
        {
            return ["q": query, "page": page]
        }

        // MARK: PaginationRequest

        func requestWithPage(_ page: Int) -> SearchRepositoriesRequest
        {
            return SearchRepositoriesRequest(query: query, page: page)
        }
    }

    struct Repository: Decodable, CustomStringConvertible
    {
        let id: Int
        let fullName: String
        let stargazersCount: Int

        static func decode(_ j: JSON) -> Decoded<Repository>
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
