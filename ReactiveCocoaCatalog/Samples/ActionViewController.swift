//
//  ActionViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import ReactiveCocoa

/// `Action` (`CocoaAction` & `RACCommand`) example.
final class ActionViewController: UIViewController, NibSceneProvider
{
    @IBOutlet var label: UILabel?
    @IBOutlet var button1: UIButton?
    @IBOutlet var button2: UIButton?

    // NOTE: CocoaAction must be retained to bind to UI
    var cocoaAction1: CocoaAction<UIButton>?
    var cocoaAction2: CocoaAction<UIButton>?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        self._setupActions()

//        _testApply()
    }

    private func _setupActions()
    {
        // action1
        let action1 = Action<UIButton?, Date, NoError> { input -> SignalProducer<Date, NoError> in
            return timer(interval: .seconds(2), on: QueueScheduler.main).take(first: 1)
        }

        // action2
        // NOTE: action2 is enabled while action1.executing is true
        let action2 = Action<UIButton?, Date, NoError>(enabledIf: action1.isExecuting) { input -> SignalProducer<Date, NoError> in
            return timer(interval: .seconds(2), on: QueueScheduler.main).take(first: 1)
        }

        self.button1?.reactive.pressed = CocoaAction(action1, input: nil)
        self.button2?.reactive.pressed = CocoaAction(action2, input: nil)

        // logging
        _setupActionLogging("action1", for: action1)
        _setupActionLogging("action2", for: action2)

        let combinedProducer: SignalProducer<String?, NoError> =
            SignalProducer.combineLatest(
                action1.isExecuting.producer.map { "action1.isExecuting = \($0)" },
                action1.isEnabled.producer.map { "action1.isEnabled   = \($0)" },
                action2.isExecuting.producer.map { "action2.isExecuting = \($0)" },
                action2.isEnabled.producer.map { "action2.isEnabled   = \($0)" }
            )
                .map { (s1: String, s2: String, s3: String, s4: String) in  // explicit type annotation to avoid slow compilation
                    "\(s1)\n\(s2)\n\(s3)\n\(s4)"
                }

        self.label!.reactive.text <~ combinedProducer
    }

}

// MARK: Tests

private func _testApply()
{
    print("\(#function) start")

    // action1
    let action1 = Action<AnyObject?, Date, NoError> { input -> SignalProducer<Date, NoError> in
        return timer(interval: .seconds(2), on: QueueScheduler.main).take(first: 1)
    }

    // action2
    // NOTE: action2 is enabled while action1.executing is true
    let action2 = Action<AnyObject?, Date, NoError>(enabledIf: action1.isExecuting) { input -> SignalProducer<Date, NoError> in
        return timer(interval: .seconds(2), on: QueueScheduler.main).take(first: 1)
    }

    // 1. `action2.apply()` fails because action1 is not executed yet
    action2.apply(nil).start(logSink("action2 (1)"))
    // [action2 (1)] FAILED NotEnabled

    // 2. `action1.apply()` succeeds (will send value after delay)
    action1.apply(nil).start(logSink("action1 (1)"))

    // 3. `action1.apply()` fails because it is already executing (disabled until value is sent & completed)
    action1.apply(nil).start(logSink("action1 (2)"))
    // [action1 (2)] FAILED NotEnabled

    // 4. `action2.apply()` succeeds (will send value after delay)
    action2.apply(nil).start(logSink("action2 (2)"))

    print("\(#function) end")

    // 5. `action1` sends value after delay
    // [action1 (1)] NEXT ...
    // [action1 (1)] COMPLETED

    // 6. `action2` sends value after delay
    // [action2 (2)] NEXT ...
    // [action2 (2)] COMPLETED
}

// MARK: Helpers

private func _setupActionLogging<In, Out, Err>(_ name: String, for action: Action<In, Out, Err>)
{
    action.isExecuting.producer.start(logSink("\(name).executing"))
    action.isEnabled.producer.start(logSink("\(name).enabled"))
    action.events.observe(logSink("\(name).events"))
    action.values.observe(logSink("\(name).values"))
    action.errors.observe(logSink("\(name).errors"))
}
