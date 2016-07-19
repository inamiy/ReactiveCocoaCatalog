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
    let refreshObserver: Observer<(), NoError>
    let loadNextObserver: Observer<(), NoError>

    let items: AnyProperty<[Req.Response.Item]>
    private let _items = MutableProperty<[Req.Response.Item]>([])

    let lastLoaded: AnyProperty<(page: Int, hasNext: Bool)>
    private let _lastLoaded = MutableProperty<(page: Int, hasNext: Bool)>(page: 0, hasNext: true)

    let loading: AnyProperty<Bool>
    private let _loading = MutableProperty(false)

    let paginationRequest: Req

    init(paginationRequest: Req)
    {
        self.paginationRequest = paginationRequest

        self.items = AnyProperty(self._items)
        self.lastLoaded = AnyProperty(self._lastLoaded)
        self.loading = AnyProperty(self._loading)

        let refreshPipe = Signal<(), NoError>.pipe()
        self.refreshObserver = refreshPipe.1

        let loadNextPipe = Signal<(), NoError>.pipe()
        self.loadNextObserver = loadNextPipe.1

        print(#function)

        let refreshRequest = refreshPipe.0
            .sampleFrom(self.loading.producer)
            .map { $1 }
            .filter { !$0 }
            .map { _ in self.paginationRequest.requestWithPage(1) }
            .on(next: { _ in print("refresh -> requestWithPage(1)") })

        let nextPageRequest = loadNextPipe.0
            .sampleFrom(self.lastLoaded.producer)
            .map { $1 }
            .sampleFrom(self.loading.producer)
            .map { ($0.0, $0.1, $1) }
            .filter { !$2 }
            .flatMap(.Merge) { page, hasNext, loading -> SignalProducer<Req, NoError> in
                if hasNext {
                    return SignalProducer(value: self.paginationRequest.requestWithPage(page + 1))
                        .on(next: { _ in print("loadNext -> requestWithPage(\(page + 1))") })
                }
                else {
                    return .empty
                }
            }

        let request = Signal<Req, NoError>.merge([refreshRequest, nextPageRequest])
            .on(event: logSink("request"))

        let response = request
            .promoteErrors(SessionTaskError)
            .flatMap(.Merge) { Session.responseProducer($0) }
            .on(event: logSink("response"))

        self._loading <~ Signal<Bool, NoError>.merge([
            request.map { _ in true },
            response
                .map { _ in false }
                .flatMapError { _ in .init(value: false) }
        ])
            .on(event: logSink("loading"))

        self._items <~ refreshPipe.0.map { [] }

        self._items <~ response
            .ignoreCastError(NoError)
            .sampleFrom(self._items.producer)
            .map { (response: Req.Response, repositories) -> [Req.Response.Item] in
                return response.hasPreviousPage
                    ? repositories + response.items
                    : response.items
            }

        self._lastLoaded <~ zip(request, response.errorToNilValue())
            .map { req, resOpt in resOpt.map { (req.page, $0.hasNextPage) } }
            .ignoreNil()
            .on(event: logSink("_lastLoaded"))

    }

    deinit { logDeinit(self) }
}
