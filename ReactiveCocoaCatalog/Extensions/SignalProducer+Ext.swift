//
//  SignalProducer+Ext.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import ReactiveCocoa

extension SignalProducer
{
    /// ignores `(error: E)` & cast ErrorType to `E2`
    public func castErrorType<E2: ErrorType>(_: E2.Type) -> SignalProducer<Value, E2>
    {
        return self.flatMapError { _ in SignalProducer<Value, E2>.empty }   // convert E to E2
    }
    
    /// a.k.a Rx.startWith (renamed to not confuse with `startWithNext()`, etc)
    public func beginWith(value: Value) -> SignalProducer<Value, Error>
    {
        return SignalProducer(value: value).concat(self)
    }
    
    public func mergeWith(other: SignalProducer<Value, Error>) -> SignalProducer<Value, Error>
    {
        return SignalProducer<SignalProducer<Value, Error>, Error>(values: [self, other]).flatten(.Merge)
    }
}