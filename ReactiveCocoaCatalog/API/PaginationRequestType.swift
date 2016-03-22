//
//  PaginationRequestType.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-03-21.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import APIKit
import Argo

protocol PaginationRequestType: RequestType
{
    typealias Response: PaginationResponseType

    var page: Int { get }

    func requestWithPage(page: Int) -> Self
}

struct PaginationResponse<Item: Decodable>: PaginationResponseType
{
    let items: [Item]

    let previousPage: Int?
    let nextPage: Int?
}

protocol PaginationResponseType
{
    typealias Item: Decodable

    var items: [Item] { get }

    var previousPage: Int? { get }
    var nextPage: Int? { get }

    init(items: [Item], previousPage: Int?, nextPage: Int?)
}

extension PaginationResponseType
{
    var hasPreviousPage: Bool
    {
        return self.previousPage != nil
    }

    var hasNextPage: Bool
    {
        return self.nextPage != nil
    }
}
