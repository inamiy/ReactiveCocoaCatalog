//
//  LogSink.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import Foundation

func logSink<T>(name: String) -> T -> ()
{
    return { arg in
        print("[\(name)] \(arg)")
    }
}