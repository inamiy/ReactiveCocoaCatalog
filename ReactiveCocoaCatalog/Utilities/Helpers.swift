//
//  Helpers.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import Foundation

// MARK: Logging

private let _maxLogCharacterCount = 200

func logSink<T>(_ name: String) -> (T) -> ()
{
    return { arg in
        var argChars = "\(arg)".characters
        argChars = argChars.prefix(_maxLogCharacterCount)
        if argChars.count == _maxLogCharacterCount {
            argChars.append("…")
        }
        print("  🚦[\(name)] \(String(argChars))")
    }
}

func deinitMessage(_ object: AnyObject) -> String
{
    return String(format: "[deinit] %@ %p", String(describing: type(of: object)), Unmanaged.passUnretained(object).toOpaque().hashValue)
}

// MARK: DateString

private let _dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
//    formatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
}()

func stringFromDate(_ date: Date) -> String
{
    return _dateFormatter.string(from: date)
}

// MARK: Random

func random(_ upperBound: Int) -> Int
{
    return Int(arc4random_uniform(UInt32(upperBound)))
}

/// Picks random `count` elements from `sequence`.
func pickRandom<S: Sequence>(_ sequence: S, _ count: Int) -> [S.Iterator.Element]
{
    var array = Array(sequence)
    var pickedArray = Array<S.Iterator.Element>()

    for _ in 0..<count {
        if array.isEmpty { break }

        pickedArray.append(array.remove(at: random(array.count)))
    }

    return pickedArray
}
