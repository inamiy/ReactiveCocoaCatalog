//
//  LogSink.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import Foundation

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
