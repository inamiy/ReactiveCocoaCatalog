//
//  BadgeManager.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-09.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Foundation
import Result
import ReactiveCocoa

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
            let property = MutableProperty<Badge>(.None)
            self._badges[menuId] = property
            return property
        }
    }

    /// - FIXME: This should be created NOT from current `_badges`-dictionary but from combined MutableProperties of badges.
    var mergedSignal: Signal<(MenuId, Badge), NoError>
    {
        var mergedSignal: Signal<(MenuId, Badge), NoError> = .never
        for (menuId, property) in self._badges {
            mergedSignal = mergedSignal.mergeWith(property.signal.map { (menuId, $0) })
        }
        return mergedSignal
    }

    private init() {}
}

// MARK: Badge

enum Badge: RawRepresentable
{
    case None
    case New    // "N" mark
    case Number(Int)
    case String(Swift.String)

    var rawValue: Swift.String?
    {
        switch self {
            case .None:              return nil
            case .New:               return "N"
            case .Number(let int):   return int > 999 ? "999+" : int > 0 ? "\(int)" : nil
            case .String(let str):   return str
        }
    }

    var number: Int?
    {
        guard case .Number(let int) = self else { return nil }
        return int
    }

    init(_ intValue: Int)
    {
        self = .Number(intValue)
    }

    init(rawValue: Swift.String?)
    {
        switch rawValue {
            case .None, .Some("0"), .Some(""):
                self = .None
            case .Some("N"):
                self = .New
            case let .Some(str):
                self = Int(str).map { .Number($0) } ?? .String(str)
        }
    }
}
