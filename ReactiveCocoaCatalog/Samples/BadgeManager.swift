//
//  BadgeManager.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-09.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Foundation
import Result
import ReactiveSwift

/// Singleton class for on-memory badge persistence.
final class BadgeManager
{
    // Singleton.
    static let badges = BadgeManager()

    private var _badges: [MenuId : MutableProperty<Badge>] = [:]

    subscript(menuId: MenuId) -> MutableProperty<Badge>
    {
        if let property = self._badges[menuId] {
            return property
        }
        else {
            let property = MutableProperty<Badge>(.none)
            self._badges[menuId] = property
            return property
        }
    }

    /// - FIXME: This should be created NOT from current `_badges`-dictionary but from combined MutableProperties of badges.
    var mergedSignal: Signal<(MenuId, Badge), NoError>
    {
        let signals = self._badges.map { menuId, property in
            return property.signal.map { (menuId, $0) }
        }
        return Signal.merge(signals)
    }

    private init() {}
}

// MARK: Badge

enum Badge: RawRepresentable
{
    case none
    case new    // "N" mark
    case number(Int)
    case string(Swift.String)

    var rawValue: Swift.String?
    {
        switch self {
            case .none:              return nil
            case .new:               return "N"
            case .number(let int):   return int > 999 ? "999+" : int > 0 ? "\(int)" : nil
            case .string(let str):   return str
        }
    }

    var number: Int?
    {
        guard case .number(let int) = self else { return nil }
        return int
    }

    init(_ intValue: Int)
    {
        self = .number(intValue)
    }

    init(rawValue: Swift.String?)
    {
        switch rawValue {
            case .none, .some("0"), .some(""):
                self = .none
            case .some("N"):
                self = .new
            case let .some(str):
                self = Int(str).map { .number($0) } ?? .string(str)
        }
    }
}
