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
import Rex

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
            .ignoreCastError(NoError)

        self.label!.rex_text <~ textProducer
            .map { "Normal: \($0!)" }

        self.throttleLabel!.rex_text <~ textProducer
            .throttle(1, onScheduler: QueueScheduler.mainQueueScheduler)    // throttle for 1 sec
            .map { "Throttled: \($0!)" }
    }
}
