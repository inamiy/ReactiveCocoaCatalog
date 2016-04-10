//
//  SequenceType+Ext.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-09.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Darwin

// MARK: Find

extension SequenceType
{
    ///
    /// Returns the first element where `predicate` returns `true`, or `nil`
    /// if such value is not found.
    ///
    /// - SeeAlso:
    /// [swift-evolution/0032-sequencetype-find.md](https://github.com/apple/swift-evolution/blob/master/proposals/0032-sequencetype-find.md)
    ///
    public func find(@noescape predicate: (Self.Generator.Element) throws -> Bool) rethrows -> Self.Generator.Element?
    {
        for elt in self {
            if try predicate(elt) {
                return elt
            }
        }
        return nil
    }

    /// Returns the first element of type `T`.
    public func find<T>(type: T.Type) -> T?
    {
        for elt in self {
            if let elt = elt as? T {
                return elt
            }
        }
        return nil
    }
}

// MARK: Shuffle

extension SequenceType
{
    public func shuffle() -> [Generator.Element]
    {
        var list = Array(self)
        list.shuffleInPlace()
        return list
    }
}

extension MutableCollectionType where Index == Int
{
    public mutating func shuffleInPlace()
    {
        for i in self.endIndex.predecessor().stride(through: self.startIndex.successor(), by: -1) {

            let randomDistance = random(self.startIndex.distanceTo(i.successor()))
            let j = self.startIndex.advancedBy(randomDistance)
            if i != j {
                swap(&self[i], &self[j])
            }
        }
    }
}
