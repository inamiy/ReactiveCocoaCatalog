//
//  ZundokoViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-03-13.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift

private let _interval = 0.5

enum Zundoko
{
    case zun
    case doko
}

///
/// Example of chanting "Ki-yo-shi!!!" after "Zun, Zun Zun, Zun Doko".
///
/// - SeeAlso:
///   - [ズンドコキヨシ with RxSwift - Qiita](http://qiita.com/bricklife/items/4bf8c0e17043498f4452)
///   - [きよしのズンドコ節 / 氷川きよし - YouTube](https://www.youtube.com/watch?v=c0H_qGSJKzE)
///
class ZundokoViewController: UIViewController, NibSceneProvider
{
    @IBOutlet weak var textView: UITextView?

    @IBOutlet weak var zunButton: UIButton?
    @IBOutlet weak var dokoButton: UIButton?

    var count = 0

    override func viewDidLoad()
    {
        super.viewDidLoad()

        self._setupViews()
        self._setupProducers()
    }

    private func _setupViews()
    {
        self.textView?.text = ""
    }

    private func _setupProducers()
    {
        let d = CompositeDisposable()

        // Manual chanting of "Zun".
        let zun = zunButton!.reactive.controlEvents(.touchUpInside)
            .map { _ in Zundoko.zun }

        // Manual chanting of "Doko".
        let doko = dokoButton!.reactive.controlEvents(.touchUpInside)
            .map { _ in Zundoko.doko }

        d += timer(interval: .milliseconds(Int(_interval * 1000)), on: QueueScheduler.main)
            .map { _ in random(2) == 0 ? Zundoko.zun : .doko }
            .merge(with: zun)
            .merge(with: doko)
            .on(value: { [weak self] zundoko in
                self?._printAll(zundoko)
            })
            .scan([]) { Array(($0 + [$1]).suffix(5)) } // collect 5 recent values
            .take { $0 != [.zun, .zun, .zun, .zun, .doko] }  // "Zun, Zun Zun, Zun Doko..."
            .concat(
                // take a deep breath
                SignalProducer.empty
                    .delay(min(_interval, 1), on: QueueScheduler.main)
            )
            .on(completed: { [weak self] in
                // "Ki-yo-shi!!!"
                self?._printAll("\n＿人人 人人 人人＿\n" + "＞ Ki-yo-shi!!! ＜\n" + "￣Y^Y^Y^Y^Y^Y￣")
            })
            .forever()  // Kiyoshi forever
            .startWithInterrupted {
                print("Kiyoshi forever!!!") // called when forever-timer is safely disposed
            }

        self.reactive.lifetime.ended.observeCompleted {
            d.dispose()
        }
    }

    private func _printAll(_ message: Any)
    {
        self.count = self.count + 1
        print("\(self.count):", message)

        guard let textView = self.textView else { return }
        textView.text = (textView.text ?? "") + "\(self.count): \(message)\n"

        // scroll down to bottom
        textView.scrollRangeToVisible(NSRange(location: textView.text.characters.count - 1, length: 0))
    }

}
