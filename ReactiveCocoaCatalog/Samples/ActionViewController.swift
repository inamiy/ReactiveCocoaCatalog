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

class ActionViewController: UIViewController
{
    @IBOutlet var label: UILabel?
    @IBOutlet var button1: UIButton?
    @IBOutlet var button2: UIButton?
    
    // NOTE: CocoaAction must be retained to bind to UI
    var cocoaAction1: CocoaAction?
    var cocoaAction2: CocoaAction?
    
    lazy var myProperty: MutableProperty<String> = MutableProperty("initial")
    
    lazy var labelProperty: DynamicProperty = DynamicProperty(object: self.label, keyPath: "text")
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self._setupActions()
        
//        _testApply()
    }
    
    func _setupActions()
    {
        // action1
        let action1 = Action<AnyObject?, NSDate, NoError> { input -> SignalProducer<NSDate, NoError> in
            
            print("action1")
            return timer(2, onScheduler: QueueScheduler.mainQueueScheduler).take(1)
        }
        
        // cocoaAction1
        self.cocoaAction1 = CocoaAction(action1, input: nil)
        self.button1?.addTarget(self.cocoaAction1, action: CocoaAction.selector, forControlEvents: .TouchUpInside)
        
        // action2
        // NOTE: action2 is enabled while action1.executing is true
        let action2 = Action<AnyObject?, NSDate, NoError>(enabledIf: action1.executing) { input -> SignalProducer<NSDate, NoError> in
            
            print("action2")
            return timer(2, onScheduler: QueueScheduler.mainQueueScheduler).take(1)
        }
        
        // cocoaAction2
        self.cocoaAction2 = CocoaAction(action2, input: nil)
        self.button2!.addTarget(self.cocoaAction2, action: CocoaAction.selector, forControlEvents: .TouchUpInside)
        
        // logging
        _setupLoggingForAction("action1", action1)
        _setupLoggingForAction("action2", action2)
        
        // bind to properties
        self.myProperty <~ action1.executing.producer.map { "action1.executing \($0)" }
        self.myProperty.producer.start(logSink("myProperty"))
        
        let combinedProducer: SignalProducer<AnyObject?, NoError> = combineLatest(
            action1.executing.producer.map { "action1.executing = \($0)" },
            action1.enabled.producer.map { "action1.enabled   = \($0)" },
            action2.executing.producer.map { "action2.executing = \($0)" },
            action2.enabled.producer.map { "action2.enabled   = \($0)" }
        )
            .map { (s1: String, s2: String, s3: String, s4: String) in  // explicit type annotation to avoid slow compilation
                "\(s1)\n\(s2)\n\(s3)\n\(s4)" as AnyObject?
            }
        self.labelProperty <~ combinedProducer
    }
}

func _testApply()
{
    let action1 = Action<AnyObject?, NSDate, NoError> { input -> SignalProducer<NSDate, NoError> in
        
        print("action1")
        return timer(2, onScheduler: QueueScheduler.mainQueueScheduler).take(1)
    }
    
    let action2 = Action<AnyObject?, NSDate, NoError>(enabledIf: action1.executing) { input -> SignalProducer<NSDate, NoError> in
        
        print("action2")
        return timer(2, onScheduler: QueueScheduler.mainQueueScheduler).take(1)
    }
    
    _setupLoggingForAction("action1", action1)
    _setupLoggingForAction("action2", action2)
    
    // ERROR: action1 is not executed yet
    action2.apply("action2 (1)").start(logSink("action2 (1)"))
    
    action1.apply("action1 (1)").start(logSink("action1 (1)"))
    
    // ERROR: action1 is already executing
    action1.apply("action1 (2)").start(logSink("action1 (2)"))
    
    action2.apply("action2 (2)").start(logSink("action2 (2)"))
}

func _setupLoggingForAction<In, Out, Err>(name: String, _ action: Action<In, Out, Err>)
{
    action.executing.producer.start(logSink("\(name).executing"))
    action.enabled.producer.start(logSink("\(name).enabled"))
    action.events.observe(logSink("\(name).events"))
    action.values.observe(logSink("\(name).values"))
    action.errors.observe(logSink("\(name).errors"))
}

