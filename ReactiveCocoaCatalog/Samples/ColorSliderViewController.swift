//
//  ColorSliderViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-07.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import ReactiveCocoa

final class ColorSliderViewController: UIViewController, NibSceneProvider
{
    @IBOutlet var colorView: UIView?

    @IBOutlet var rSlider: UISlider?
    @IBOutlet var gSlider: UISlider?
    @IBOutlet var bSlider: UISlider?

    @IBOutlet var rLabel: UILabel?
    @IBOutlet var gLabel: UILabel?
    @IBOutlet var bLabel: UILabel?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let red = SignalProducer(self.rSlider!.reactive.controlEvents(.valueChanged))
            .map { $0.value }
            .prefix(value: self.rSlider!.value) // use current value first for `combineLatest`
            .map(CGFloat.init(_:))

        let green = SignalProducer(self.gSlider!.reactive.controlEvents(.valueChanged))
            .map { $0.value }
            .prefix(value: self.gSlider!.value)
            .map(CGFloat.init(_:))

        let blue = SignalProducer(self.bSlider!.reactive.controlEvents(.valueChanged))
            .map { $0.value }
            .prefix(value: self.bSlider!.value)
            .map(CGFloat.init(_:))

        let rgb = SignalProducer.combineLatest(red, green, blue)
            .map { r, g, b in UIColor(red: r, green: g, blue: b, alpha: 1) }
            .on(event: logSink("rgb"))

        self.colorView!.reactive.backgroundColor <~ rgb.map { $0 }

        self.rLabel!.reactive.text <~ red.map(_sliderValueToString)
        self.gLabel!.reactive.text <~ green.map(_sliderValueToString)
        self.bLabel!.reactive.text <~ blue.map(_sliderValueToString)
    }
}

// MARK: Helpers

private func _sliderValueToString(value: CGFloat) -> String?
{
    let uint8 = UInt8(round(value * 255))
    let hex = String(format: "%X", uint8)
    return "\(uint8) (\(hex))"
}
