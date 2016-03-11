//
//  TextFieldViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa

class TextFieldViewController: UIViewController
{
    @IBOutlet var label: UILabel?
    @IBOutlet var throttleLabel: UILabel?
    @IBOutlet var debounceLabel: UILabel?   // TODO: implement when `debounce()` is ready
    @IBOutlet var textField: UITextField?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let textProducer = self.textField!.rac_textSignal().toSignalProducer()
            .castErrorType(NoError)
        
        let labelProperty = DynamicProperty(object: self.label, keyPath: "text")
        let throttleLabelProperty = DynamicProperty(object: self.throttleLabel, keyPath: "text")
        
        labelProperty <~ textProducer
            .map { "Normal: \($0!)" }
        
        throttleLabelProperty <~ textProducer
            .throttle(1, onScheduler: QueueScheduler.mainQueueScheduler)    // throttle for 1 sec
            .map { "Throttled: \($0!)" }
    }
}