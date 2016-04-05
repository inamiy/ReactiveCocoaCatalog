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

func logSink<T>(name: String) -> T -> ()
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

func logDeinit(object: AnyObject)
{
    let addr = String(format: "%p", unsafeAddressOf(object))
    print("\n", "[deinit] \(object) \(addr)", "\n")
}

// MARK: DateString

private let _dateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
//    formatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
}()

func stringFromDate(date: NSDate) -> String
{
    return _dateFormatter.stringFromDate(date)
}

// MARK: Random

func random(upperBound: Int) -> Int
{
    return Int(arc4random_uniform(UInt32(upperBound)))
}

/// Picks random `count` elements from `sequence`.
func pickRandom<S: SequenceType>(sequence: S, _ count: Int) -> [S.Generator.Element]
{
    var array = Array(sequence)
    var pickedArray = Array<S.Generator.Element>()

    for _ in 0..<count {
        if array.isEmpty { break }

        pickedArray.append(array.removeAtIndex(random(array.count)))
    }

    return pickedArray
}
