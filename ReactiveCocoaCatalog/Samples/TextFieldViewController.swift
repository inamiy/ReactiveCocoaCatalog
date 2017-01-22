//
//  TextFieldViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import ReactiveCocoa

class TextFieldViewController: UIViewController, NibSceneProvider
{
    @IBOutlet var label: UILabel?
    @IBOutlet var throttleLabel: UILabel?
    @IBOutlet var debounceLabel: UILabel?   // TODO: implement when `debounce()` is ready
    @IBOutlet var textField: UITextField?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let textProducer = self.textField!.reactive.continuousTextValues

        self.label!.reactive.text <~ textProducer
            .map { "Normal: \($0!)" }

        self.throttleLabel!.reactive.text <~ textProducer
            .throttle(1, on: QueueScheduler.main)    // throttle for 1 sec
            .map { "Throttled: \($0!)" }
    }
}
