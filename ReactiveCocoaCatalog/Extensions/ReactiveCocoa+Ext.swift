//
//  ReactiveCocoa+Ext.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import Result
import ReactiveCocoa

// MARK: Swift

extension Signal
{
    /// Ignores `(error: Error)` & cast ErrorType to `Error2`.
    @warn_unused_result(message="Did you forget to call `observe` on the signal?")
    public func ignoreCastError<Error2: ErrorType>(_: Error2.Type) -> Signal<Value, Error2>
    {
        return self.flatMapError { _ in SignalProducer<Value, Error2>.empty }
    }

    /// Converts error to single nil value, i.e. from `.Failed` to `.Next(nil)` + `.Complete`.
    @warn_unused_result(message="Did you forget to call `observe` on the signal?")
    public func errorToNilValue() -> Signal<Value?, NoError>
    {
        return self
            .map(Optional.init)
            .flatMapError { _ in .init(value: nil) }
    }

    /// Converts to `Signal<(), NoError>` (ignoring value & error),
    /// useful as a trigger signal for `sampleOn`, `takeUntil`, `skipUntil`.
    @warn_unused_result(message="Did you forget to call `observe` on the signal?")
    public func triggerize() -> Signal<(), NoError>
    {
        return self
            .ignoreCastError(NoError)
            .map { _ in () }
    }

    /// Zips `self` with `otherSignal`, using `self` as a sampler.
    /// - Warning: `zip` may fail if `self` (as sampler) emits faster than `otherSignal` on 1st value.
    @warn_unused_result(message="Did you forget to call `observe` on the signal?")
    public func sampleFrom<Value2>(otherSignal: Signal<Value2, Error>) -> Signal<(Value, Value2), Error>
    {
        return zip(self, otherSignal.sampleOn(self.triggerize()))
    }

    /// Zips `self` with `otherSignalProducer`, using `self` as a sampler.
    @warn_unused_result(message="Did you forget to call `observe` on the signal?")
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

    @warn_unused_result(message="Did you forget to call `observe` on the signal?")
    public func mergeWith(other: Signal<Value, Error>) -> Signal<Value, Error>
    {
        return Signal { observer in
            let d = CompositeDisposable()
            d += self.observe(observer)
            d += other.observe(observer)
            return d
        }
    }

    public func animate(duration duration: NSTimeInterval, options: UIViewAnimationOptions = [.AllowUserInteraction]) -> Signal<Value, Error>
    {
        return Signal<Value, Error> { observer in
            return self.observe { (event: Event<Value, Error>) in
                switch event {
                    case let .Next(value):
                        UIView.animateWithDuration(duration, delay: 0, options: options, animations: {
                            observer.sendNext(value)
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

extension SignalProducer
{
    /// Ignores `(error: Error)` & cast ErrorType to `Error2`.
    @warn_unused_result(message="Did you forget to call `start` on the producer?")
    public func ignoreCastError<Error2: ErrorType>(_: Error2.Type) -> SignalProducer<Value, Error2>
    {
        return lift { $0.ignoreCastError(Error2) }
    }

    /// Converts error to single nil value, i.e. `.Failed` to `.Next(nil)` + `.Complete`.
    @warn_unused_result(message="Did you forget to call `start` on the producer?")
    public func errorToNilValue() -> SignalProducer<Value?, NoError>
    {
        return lift { $0.errorToNilValue() }
    }

    /// Converts to `SignalProducer<(), NoError>` (ignoring value & error),
    /// useful as a trigger signal for `sampleOn`, `takeUntil`, `skipUntil`.
    @warn_unused_result(message="Did you forget to call `start` on the producer?")
    public func triggerize() -> SignalProducer<(), NoError>
    {
        return lift { $0.triggerize() }
    }

    /// Zips `self` with `otherSignalProducer`, using `self` as a sampler.
    @warn_unused_result(message="Did you forget to call `start` on the producer?")
    public func sampleFrom<Value2>(otherSignalProducer: SignalProducer<Value2, Error>) -> SignalProducer<(Value, Value2), Error>
    {
        return lift(Signal.sampleFrom)(otherSignalProducer)
    }

    /// - SeeAlso: `Rx.startWith` (renamed to not confuse with `startWithNext()`)
    @warn_unused_result(message="Did you forget to call `start` on the producer?")
    public func beginWith(value: Value) -> SignalProducer<Value, Error>
    {
        return SignalProducer(value: value).concat(self)
    }

    @warn_unused_result(message="Did you forget to call `start` on the producer?")
    public func mergeWith(other: SignalProducer<Value, Error>) -> SignalProducer<Value, Error>
    {
        return SignalProducer<SignalProducer<Value, Error>, Error>(values: [self, other]).flatten(.Merge)
    }

    /// Repeats `self` forever.
    @warn_unused_result(message="Did you forget to call `start` on the producer?")
    public func forever() -> SignalProducer<Value, Error>
    {
        return SignalProducer { observer, disposable in
            let serialDisposable = SerialDisposable()
            disposable.addDisposable(serialDisposable)

            func iterate() {
                self.startWithSignal { signal, signalDisposable in
                    serialDisposable.innerDisposable = signalDisposable

                    signal.observe { event in
                        switch event {
                            case .Failed, .Completed: // NOTE: not for .Interrupted
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
    public func animate(duration duration: NSTimeInterval, options: UIViewAnimationOptions = [.AllowUserInteraction]) -> SignalProducer<Value, Error>
    {
        return lift { $0.animate(duration: duration, options: options) }
    }
}

// MARK: Scheduler / GCD

public func timer(interval: NSTimeInterval) -> SignalProducer<NSDate, NoError>
{
    return timer(interval, onScheduler: QueueScheduler.mainQueueScheduler)
}

public func scheduleAfterNow(seconds: NSTimeInterval, action: () -> ()) -> Disposable?
{
    return QueueScheduler.mainQueueScheduler.scheduleAfterNow(seconds, action: action)
}

extension QueueScheduler
{
    public func scheduleAfterNow(seconds: NSTimeInterval, action: () -> ()) -> Disposable?
    {
        return self.scheduleAfter(NSDate(timeIntervalSinceNow: seconds), action: action)
    }
}

extension Signal
{
    public func delay(interval: NSTimeInterval) -> Signal<Value, Error>
    {
        return self.delay(interval, onScheduler: QueueScheduler.mainQueueScheduler)
    }
}

extension SignalProducer
{
    public func delay(interval: NSTimeInterval) -> SignalProducer<Value, Error>
    {
        return lift { $0.delay(interval) }
    }
}

// MARK: Action

/// Helper for attaching trigger action to UI components where Input = sender = AnyObject?.
func triggerAction() -> Action<AnyObject?, (), NoError>
{
    return .init({ _ in .init(value: ()) })
}

// MARK: Foundation

extension RACCommand
{
    public static func triggerCommand() -> RACCommand
    {
        return toRACCommand(Action<AnyObject?, AnyObject?, NoError> { _ in .init(value: nil) })
    }
}

extension NSObject
{
    /// Easy selector hook, discarding value and error.
    public func racc_hookSelector(selector: Selector) -> SignalProducer<(), NoError>
    {
        return self.rac_signalForSelector(selector).toSignalProducer()
            .triggerize()
    }
}

extension NSData
{
    /// Synchronous fetching of remote data.
    static func racc_downloadDataProducer(url: NSURL) -> SignalProducer<NSData?, NoError>
    {
        return SignalProducer { observer, disposable in
            let data = NSData(contentsOfURL: url)
            observer.sendNext(data)
            observer.sendCompleted()
        }
    }
}

extension NSCache
{
    /// Synchronous cache loading.
    func racc_objectProducer<T: AnyObject>(key key: AnyObject) -> SignalProducer<T?, NoError>
    {
        return SignalProducer { [weak self] observer, disposable in
            observer.sendNext(self?.objectForKey(key) as? T)
            observer.sendCompleted()
        }
    }
}

// MARK: UIKit

extension UIImage
{
    /// Synchronous fetching of remote image.
    static func racc_downloadImageProducer(url: NSURL) -> SignalProducer<UIImage?, NoError>
    {
        return NSData.racc_downloadDataProducer(url)
            .map { $0.flatMap(UIImage.init) }
    }
}

// MARK: Objective-C Bridging

private func defaultNSError(message: String, file: String, line: Int) -> NSError
{
    return Result<(), NSError>.error(message, file: file, line: line)
}

extension RACSignal
{
    /// Creates a Signal which will subscribe to the receiver immediately.
    public func toSignal(file: String = #file, line: Int = #line) -> Signal<AnyObject?, NSError>
    {
        return Signal { observer in
            let next = { obj in
                observer.sendNext(obj)
            }

            let failed = { nsError in
                observer.sendFailed(nsError ?? defaultNSError("Nil RACSignal error", file: file, line: line))
            }

            let completed = {
                observer.sendCompleted()
            }

            return self.subscribeNext(next, error: failed, completed: completed)
        }
    }
}

extension RACCompoundDisposable
{
    /// For easy handling of `rac_deallocDisposable` in Swift.
    public func addDisposable(disposable: Disposable?)
    {
        self.addDisposable(RACDisposable {
            disposable?.dispose()
        })
    }
}

/// For easy handling of `rac_deallocDisposable` in Swift.
public func += (lhs: RACCompoundDisposable, rhs: Disposable?)
{
    return lhs.addDisposable(rhs)
}
