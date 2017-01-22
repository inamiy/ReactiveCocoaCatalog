//
//  SequenceType+Ext.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-09.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Darwin

// MARK: Find

extension Sequence
{
    /// Returns the first element of type `T` with casting.
    public func find<T>(_ type: T.Type) -> T?
    {
        for elem in self {
            if let elem = elem as? T {
                return elem
            }
        }
        return nil
    }
}

// MARK: Shuffle

extension Sequence
{
    public func shuffled() -> [Iterator.Element]
    {
        var list = Array(self)
        list.shuffle()
        return list
    }
}

extension MutableCollection where Index: Strideable, Index.Stride == Int
{
    public mutating func shuffle()
    {
        if self.isEmpty || self.startIndex + 1 == self.endIndex { return }

        for i in stride(from: self.endIndex - 1, through: self.startIndex + 1, by: -1) {
            let randomDistance = random(self.startIndex.distance(to: i + 1))
            let j = self.startIndex.advanced(by: randomDistance)
            if i != j {
                swap(&self[i], &self[j])
            }
        }
    }
}
