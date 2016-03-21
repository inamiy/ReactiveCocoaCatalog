//
//  PaginationViewModel.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-03-21.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Foundation
import Result
import ReactiveCocoa
import APIKit
import Argo

final class PaginationViewModel<Req: PaginationRequestType>
{
    let refreshPipe = Signal<(), NoError>.pipe()
    let loadNextPipe = Signal<(), NoError>.pipe()

    let items = MutableProperty<[Req.Response.Item]>([])

    let hasNextPage = MutableProperty<Bool>(false)
    let loading = MutableProperty<Bool>(false)

    let paginationRequest: Req

    init(paginationRequest: Req)
    {
        self.paginationRequest = paginationRequest

        self._setupSignals(nextPage: nil)
    }

    deinit
    {
        let addr = String(format: "%p", unsafeAddressOf(self))
        print("\n", "[deinit] \(self) \(addr)", "\n")
    }

    private func _setupSignals(nextPage nextPage: Int?)
    {
        print(__FUNCTION__, nextPage)

        let refreshRequest = refreshPipe.0
            .take(1)
            .on(next: { print("refresh -> requestWithPage(1)") })
            .map { self.paginationRequest.requestWithPage(1) }

        let nextPageRequest = loadNextPipe.0
            .take(1)
            .on(next: { print("loadNext -> requestWithPage(\(nextPage))") })
            .flatMap(.Merge) { _ -> SignalProducer<Req, NoError> in
                if let nextPage = nextPage {
                    return .init(value: self.paginationRequest.requestWithPage(nextPage))
                }
                else {
                    return .empty
                }
            }

        let request = Signal<Req, NoError>.merge([refreshRequest, nextPageRequest])
            .take(1)
            .on(event: logSink("request"))

        let response = request
            .promoteErrors(APIError)
            .flatMap(.Merge) { Session.responseProducer($0) }
            .on(event: logSink("response"))

        self.loading <~ Signal<Bool, NoError>.merge([
            request.map { _ in true },
            response
                .map { _ in false }
                .flatMapError { _ in SignalProducer<Bool, NoError>(value: false) }
        ])
            .on(event: logSink("loading"))

        self.items <~ refreshPipe.0.map { [] }

        self.items <~ combineLatest(
            self.items.producer,
            SignalProducer(signal: response.ignoreCastError(NoError))
        )
            .map { (repositories, response: Req.Response) -> [Req.Response.Item] in
                return response.hasPreviousPage
                    ? repositories + response.items
                    : response.items
            }
            .take(1)
            .observeOn(QueueScheduler.mainQueueScheduler) // avoid NSLock deadlock
//            .on(event: logSink("items"))

        self.hasNextPage <~ response
            .map { $0.hasNextPage }
            .ignoreCastError(NoError)

        response.observeNext { [weak self] response in
            self?._setupSignals(nextPage: response.nextPage)
        }
    }
}