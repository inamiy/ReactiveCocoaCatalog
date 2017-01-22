//
//  BingAPI.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import Foundation
import ReactiveSwift
import APIKit

public protocol BingRequest: Request {}

extension BingRequest
{
    public var baseURL: URL
    {
        return URL(string: "https://api.bing.com")!
    }
}

public struct BingSearchRequest: BingRequest
{
    internal let query: String

    public var method: HTTPMethod
    {
        return .get
    }

    public var path: String
    {
        return "/osjson.aspx"
    }

    public var queryParameters: [String : Any]?
    {
        return ["query": self.query]
    }

    public init(query: String)
    {
        self.query = query
    }

    public func response(from object: Any, urlResponse: HTTPURLResponse) throws -> BingSearchResponse
    {
//        print("response object = \(object)")

        guard let arr = object as? [AnyObject], arr.count == 2 else {
            throw ResponseError.unexpectedObject(object)
        }

        let query = arr[0] as? String ?? ""
        let suggestions = arr[1] as? [String] ?? []

        return BingSearchResponse(query: query, suggestions: suggestions)
    }
}

public struct BingSearchResponse
{
    public let query: String
    public let suggestions: [String]
}

public struct BingAPI
{
    public static func searchProducer(query: String) -> SignalProducer<BingSearchResponse, SessionTaskError>
    {
        return SignalProducer { observer, disposable in
            let request = BingSearchRequest(query: query)

            Session.send(request) { result in
                switch result {
                    case .success(let response):
                        observer.send(value: response)
                        observer.sendCompleted()
                    case .failure(let error):
                        observer.send(error: error)
                }
            }
        }
    }
}
