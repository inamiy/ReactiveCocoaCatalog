//
//  APIKit+Ext.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-03-21.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Foundation
import ReactiveSwift
import APIKit
import Argo

// MARK: APIKit + ReactiveCocoa

extension Session
{
    static func responseProducer<Req: Request>(_ request: Req) -> SignalProducer<Req.Response, SessionTaskError>
    {
        return SignalProducer { observer, disposable in
            let task = Session.send(request) { result in
                switch result {
                    case .success(let response):
                        observer.send(value: response)
                        observer.sendCompleted()
                    case .failure(let error):
                        observer.send(error: error)
                }
            }

            disposable.add {
                task?.cancel()
            }
        }
    }
}

// MARK: APIKit + Argo

extension Request where Response: Decodable, Response.DecodedType == Response
{
    /// Automatic decoding.
    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response
    {
        return try decode(object).dematerialize()
    }
}
