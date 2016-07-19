//
//  APIKit+Ext.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-03-21.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Foundation
import ReactiveCocoa
import APIKit
import Argo

// MARK: APIKit + ReactiveCocoa

extension Session
{
    static func responseProducer<Req: RequestType>(request: Req) -> SignalProducer<Req.Response, SessionTaskError>
    {
        return SignalProducer { observer, disposable in
            let task = Session.sendRequest(request) { result in
                switch result {
                    case .Success(let response):
                        observer.sendNext(response)
                        observer.sendCompleted()
                    case .Failure(let error):
                        observer.sendFailed(error)
                }
            }

            disposable.addDisposable {
                task?.cancel()
            }
        }
    }
}

// MARK: APIKit + Argo

extension RequestType where Response: Decodable, Response.DecodedType == Response
{
    /// Automatic decoding.
    func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response
    {
        return try decode(object).dematerialize()
    }
}
