//
//  BingAPI.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import Foundation
import ReactiveCocoa
import APIKit

public protocol BingRequest: RequestType {}

extension BingRequest
{
    public var baseURL: NSURL
    {
        return NSURL(string: "https://api.bing.com")!
    }
}

public struct BingSearchRequest: BingRequest
{
    internal let query: String

    public var method: HTTPMethod
    {
        return .GET
    }

    public var path: String
    {
        return "/osjson.aspx"
    }

    public var queryParameters: [String : AnyObject]?
    {
        return ["query" : self.query]
    }

    public init(query: String)
    {
        self.query = query
    }

    public func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> BingSearchResponse
    {
//        print("response object = \(object)")

        guard let arr = object as? [AnyObject] where arr.count == 2 else {
            throw ResponseError.UnexpectedObject(object)
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

            Session.sendRequest(request) { result in
                switch result {
                    case .Success(let response):
                        observer.sendNext(response)
                        observer.sendCompleted()
                    case .Failure(let error):
                        observer.sendFailed(error)
                }
            }
        }
    }
}
