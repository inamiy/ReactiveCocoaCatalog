//
//  SignalProducer+Ext.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import Result
import ReactiveCocoa

extension NSObject
{
    /// Easy selector hook, discarding value and error.
    public func racc_hookSelector(selector: Selector) -> SignalProducer<(), NoError>
    {
        return self.rac_signalForSelector(selector).toSignalProducer()
            .map { _ in () }
            .ignoreCastError(NoError)
    }
}

extension Signal
{
    /// Ignores `(error: E)` & cast ErrorType to `E2`.
    public func ignoreCastError<E2: ErrorType>(_: E2.Type) -> Signal<Value, E2>
    {
        return self.flatMapError { _ in SignalProducer<Value, E2>.empty }   // convert E to E2
    }
}

extension SignalProducer
{
    /// Ignores `(error: E)` & cast ErrorType to `E2`.
    public func ignoreCastError<E2: ErrorType>(_: E2.Type) -> SignalProducer<Value, E2>
    {
        return lift { $0.ignoreCastError(E2) }
    }
    
    /// - SeeAlso: `Rx.startWith` (renamed to not confuse with `startWithNext()`)
    public func beginWith(value: Value) -> SignalProducer<Value, Error>
    {
        return SignalProducer(value: value).concat(self)
    }
    
    public func mergeWith(other: SignalProducer<Value, Error>) -> SignalProducer<Value, Error>
    {
        return SignalProducer<SignalProducer<Value, Error>, Error>(values: [self, other]).flatten(.Merge)
    }
}
