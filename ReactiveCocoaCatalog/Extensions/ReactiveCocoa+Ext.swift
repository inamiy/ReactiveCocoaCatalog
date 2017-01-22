//
//  ReactiveCocoa+Ext.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift

// MARK: Swift

extension SignalProtocol
{
    /// Ignores values & cast `Value` to `Value2`.
    public func ignoreCastValue<Value2>(_: Value2.Type) -> Signal<Value2, Error> {
        return self.flatMap(.merge) { _ in SignalProducer<Value2, Error>.empty }
    }

    /// Ignores error & cast `Error` to `Error2`.
    public func ignoreCastError<Error2: Swift.Error>(_: Error2.Type) -> Signal<Value, Error2>
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

    public func merge(with other: Signal<Value, Error>) -> Signal<Value, Error>
    {
        return Signal.merge(self.signal, other)
    }

    public func animate(duration: TimeInterval, options: UIViewAnimationOptions = [.allowUserInteraction]) -> Signal<Value, Error>
    {
        return Signal<Value, Error> { observer in
            return self.observe { (event: Event<Value, Error>) in
                switch event {
                    case let .value(value):
                        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                            observer.send(value: value)
                        }, completion: { finished in
                            observer.sendCompleted()
                        })
                    default:
                        observer.sendCompleted()
                }
            }
        }
    }
}

extension SignalProducerProtocol
{
    /// Ignores values & cast `Value` to `Value2`.
    public func ignoreCastValue<Value2>(_: Value2.Type) -> SignalProducer<Value2, Error> {
        return lift { $0.ignoreCastValue(Value2.self) }
    }

    /// Ignores error & cast `Error` to `Error2`.
    public func ignoreCastError<Error2: Swift.Error>(_: Error2.Type) -> SignalProducer<Value, Error2>
    {
        return lift { $0.ignoreCastError(Error2.self) }
    }

    /// Converts error to single nil value, i.e. `.Failed` to `.Next(nil)` + `.Complete`.
    public func errorToNilValue() -> SignalProducer<Value?, NoError>
    {
        return lift { $0.errorToNilValue() }
    }

    public func merge(with other: Signal<Value, Error>) -> SignalProducer<Value, Error>
    {
        return self.merge(with: SignalProducer(other))
    }

    public func merge(with other: SignalProducer<Value, Error>) -> SignalProducer<Value, Error>
    {
        return SignalProducer<SignalProducer<Value, Error>, Error>([self.producer, other]).flatten(.merge)
    }

    public func animate(duration: TimeInterval, options: UIViewAnimationOptions = [.allowUserInteraction]) -> SignalProducer<Value, Error>
    {
        return lift { $0.animate(duration: duration, options: options) }
    }

    /// Repeats `self` forever.
    public func forever() -> SignalProducer<Value, Error>
    {
        return SignalProducer { observer, disposable in
            let serialDisposable = SerialDisposable()
            disposable.add(serialDisposable)

            func iterate() {
                self.startWithSignal { signal, signalDisposable in
                    serialDisposable.inner = signalDisposable

                    signal.observe { event in
                        switch event {
                            case .failed, .completed: // NOTE: not for .Interrupted
                                iterate()
                            default:
                                observer.action(event)
                        }
                    }
                }
            }

            iterate()
        }
    }
}

// MARK: Scheduler / GCD

extension QueueScheduler
{
    public func schedule(after seconds: TimeInterval, action: @escaping () -> ()) -> Disposable?
    {
        return self.schedule(after: Date(timeIntervalSinceNow: seconds), action: action)
    }
}

// MARK: Networking

extension Data
{
    /// Synchronous fetching of remote data.
    static func racc_downloadDataProducer(url: URL) -> SignalProducer<Data?, NoError>
    {
        return SignalProducer { observer, disposable in
            let data = try? Data.init(contentsOf: url)
            observer.send(value: data)
            observer.sendCompleted()
        }
    }
}

extension UIImage
{
    /// Synchronous fetching of remote image.
    static func racc_downloadImageProducer(url: URL) -> SignalProducer<UIImage?, NoError>
    {
        return Data.racc_downloadDataProducer(url: url)
            .map { $0.flatMap(UIImage.init) }
    }
}
