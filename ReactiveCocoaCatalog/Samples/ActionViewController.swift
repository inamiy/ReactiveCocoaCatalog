//
//  ActionViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa

private enum _DemoMode { case CocoaAction, RACCommand }
private let _demoMode = _DemoMode.RACCommand    // toggle this flag to see difference

/// `Action` (`CocoaAction` & `RACCommand`) example.
final class ActionViewController: UIViewController
{
    @IBOutlet var label: UILabel?
    @IBOutlet var button1: UIButton?
    @IBOutlet var button2: UIButton?

    // NOTE: CocoaAction must be retained to bind to UI
    var cocoaAction1: CocoaAction?
    var cocoaAction2: CocoaAction?

    deinit { logDeinit(self) }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        self._setupActions()

//        _testApply()
    }

    private func _setupActions()
    {
        // action1
        let action1 = Action<AnyObject?, NSDate, NoError> { input -> SignalProducer<NSDate, NoError> in
            return timer(2, onScheduler: QueueScheduler.mainQueueScheduler).take(1)
        }

        // action2
        // NOTE: action2 is enabled while action1.executing is true
        let action2 = Action<AnyObject?, NSDate, NoError>(enabledIf: action1.executing) { input -> SignalProducer<NSDate, NoError> in
            return timer(2, onScheduler: QueueScheduler.mainQueueScheduler).take(1)
        }

        switch _demoMode {
            case .CocoaAction:
                self.cocoaAction1 = CocoaAction(action1, input: nil)
                self.button1?.addTarget(self.cocoaAction1, action: CocoaAction.selector, forControlEvents: .TouchUpInside)

                self.cocoaAction2 = CocoaAction(action2, input: nil)
                self.button2!.addTarget(self.cocoaAction2, action: CocoaAction.selector, forControlEvents: .TouchUpInside)

            case .RACCommand:
                self.button1!.rac_command = toRACCommand(action1)
                self.button2!.rac_command = toRACCommand(action2)
        }

        // logging
        _setupLoggingForAction("action1", action1)
        _setupLoggingForAction("action2", action2)

        let combinedProducer: SignalProducer<String, NoError> =
            combineLatest(
                action1.executing.producer.map { "action1.executing = \($0)" },
                action1.enabled.producer.map { "action1.enabled   = \($0)" },
                action2.executing.producer.map { "action2.executing = \($0)" },
                action2.enabled.producer.map { "action2.enabled   = \($0)" })
                .map { (s1: String, s2: String, s3: String, s4: String) in  // explicit type annotation to avoid slow compilation
                    "\(s1)\n\(s2)\n\(s3)\n\(s4)"
                }

        self.label!.rex_text <~ combinedProducer
    }

}

// MARK: Tests

private func _testApply()
{
    print("\(#function) start")

    // action1
    let action1 = Action<AnyObject?, NSDate, NoError> { input -> SignalProducer<NSDate, NoError> in
        return timer(2, onScheduler: QueueScheduler.mainQueueScheduler).take(1)
    }

    // action2
    // NOTE: action2 is enabled while action1.executing is true
    let action2 = Action<AnyObject?, NSDate, NoError>(enabledIf: action1.executing) { input -> SignalProducer<NSDate, NoError> in
        return timer(2, onScheduler: QueueScheduler.mainQueueScheduler).take(1)
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

private func _setupLoggingForAction<In, Out, Err>(name: String, _ action: Action<In, Out, Err>)
{
    action.executing.producer.start(logSink("\(name).executing"))
    action.enabled.producer.start(logSink("\(name).enabled"))
    action.events.observe(logSink("\(name).events"))
    action.values.observe(logSink("\(name).values"))
    action.errors.observe(logSink("\(name).errors"))
}
