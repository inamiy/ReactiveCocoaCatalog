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
            .triggerize()
    }
}

extension Signal
{
    /// Ignores `(error: Error)` & cast ErrorType to `Error2`.
    public func ignoreCastError<Error2: ErrorType>(_: Error2.Type) -> Signal<Value, Error2>
    {
        return self.flatMapError { _ in SignalProducer<Value, Error2>.empty }
    }

    /// Converts error to single nil value, i.e. from `.Failed` to `.Next(nil)` + `.Complete`.
    public func errorToNilValue() -> Signal<Value?, NoError>
    {
        return self
            .map(Optional.init)
            .flatMapError { _ in .init(value: nil) }
    }

    /// Converts to `Signal<(), NoError>` (ignoring value & error),
    /// useful as a trigger signal for `sampleOn`, `takeUntil`, `skipUntil`.
    public func triggerize() -> Signal<(), NoError>
    {
        return self
            .ignoreCastError(NoError)
            .map { _ in () }
    }

    /// Zips `self` with `otherSignal`, using `self` as a sampler.
    /// - Warning: `zip` may fail if `self` (as sampler) emits faster than `otherSignal` on 1st value.
    public func sampleFrom<Value2>(otherSignal: Signal<Value2, Error>) -> Signal<(Value, Value2), Error>
    {
        return zip(self, otherSignal.sampleOn(self.triggerize()))
    }

    /// Zips `self` with `otherSignalProducer`, using `self` as a sampler.
    public func sampleFrom<Value2>(otherSignalProducer: SignalProducer<Value2, Error>) -> Signal<(Value, Value2), Error>
    {
        return Signal<(Value, Value2), Error> { observer in
            let d = SerialDisposable()
            otherSignalProducer.startWithSignal { signal, disposable in
                self.sampleFrom(signal).observe(observer)
                d.innerDisposable = disposable
            }
            return d
        }
    }
}

extension SignalProducer
{
    /// Ignores `(error: Error)` & cast ErrorType to `Error2`.
    public func ignoreCastError<Error2: ErrorType>(_: Error2.Type) -> SignalProducer<Value, Error2>
    {
        return lift { $0.ignoreCastError(Error2) }
    }

    /// Converts error to single nil value, i.e. `.Failed` to `.Next(nil)` + `.Complete`.
    public func errorToNilValue() -> SignalProducer<Value?, NoError>
    {
        return lift { $0.errorToNilValue() }
    }

    /// Converts to `SignalProducer<(), NoError>` (ignoring value & error),
    /// useful as a trigger signal for `sampleOn`, `takeUntil`, `skipUntil`.
    public func triggerize() -> SignalProducer<(), NoError>
    {
        return lift { $0.triggerize() }
    }

    /// Zips `self` with `otherSignalProducer`, using `self` as a sampler.
    public func sampleFrom<Value2>(otherSignalProducer: SignalProducer<Value2, Error>) -> SignalProducer<(Value, Value2), Error>
    {
        return lift(Signal.sampleFrom)(otherSignalProducer)
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
