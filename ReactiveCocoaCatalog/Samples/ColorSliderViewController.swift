//
//  ColorSliderViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-07.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa
import Rex

final class ColorSliderViewController: UIViewController
{
    @IBOutlet var colorView: UIView?

    @IBOutlet var rSlider: UISlider?
    @IBOutlet var gSlider: UISlider?
    @IBOutlet var bSlider: UISlider?

    @IBOutlet var rLabel: UILabel?
    @IBOutlet var gLabel: UILabel?
    @IBOutlet var bLabel: UILabel?

    deinit { logDeinit(self) }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let red = rSlider!.rac_signalForControlEvents(.ValueChanged).toSignalProducer()
            .map { ($0 as! UISlider).value }
            .beginWith(self.rSlider!.value) // use current value first for `combineLatest`
            .map(CGFloat.init(_:))
            .ignoreCastError(NoError)

        let green = gSlider!.rac_signalForControlEvents(.ValueChanged).toSignalProducer()
            .map { ($0 as! UISlider).value }
            .beginWith(self.gSlider!.value)
            .map(CGFloat.init(_:))
            .ignoreCastError(NoError)

        let blue = bSlider!.rac_signalForControlEvents(.ValueChanged).toSignalProducer()
            .map { ($0 as! UISlider).value }
            .beginWith(self.bSlider!.value)
            .map(CGFloat.init(_:))
            .ignoreCastError(NoError)

        let rgb = combineLatest(red, green, blue)
            .map { r, g, b in UIColor(red: r, green: g, blue: b, alpha: 1) }
            .on(event: logSink("rgb"))

        self.colorView!.rex_backgroundColor <~ rgb.map { $0 }

        self.rLabel!.rex_text <~ red.map(_sliderValueToString)
        self.gLabel!.rex_text <~ green.map(_sliderValueToString)
        self.bLabel!.rex_text <~ blue.map(_sliderValueToString)
    }
}

// MARK: Helpers

private func _sliderValueToString(value: CGFloat) -> String
{
    let uint8 = UInt8(round(value * 255))
    let hex = String(format: "%X", uint8)
    return "\(uint8) (\(hex))"
}
