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
    public func castErrorType<E2: ErrorType>(_: E2.Type) -> SignalProducer<T, E2>
    {
        return self.flatMapError { _ in SignalProducer<T, E2>.empty }   // convert E to E2
    }
    
    /// a.k.a Rx.startWith (renamed to not confuse with `startWithNext()`, etc)
    public func beginWith(value: T) -> SignalProducer<T, E>
    {
        return SignalProducer(value: value).concat(self)
    }
    
    public func mergeWith(other: SignalProducer<T, E>) -> SignalProducer<T, E>
    {
        return SignalProducer<SignalProducer<T, E>, E>(values: [self, other]).flatten(.Merge)
    }
}