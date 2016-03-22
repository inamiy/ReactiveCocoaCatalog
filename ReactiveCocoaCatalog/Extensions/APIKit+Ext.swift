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

extension Session
{
    static func responseProducer<Req: RequestType>(request: Req) -> SignalProducer<Req.Response, APIError>
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