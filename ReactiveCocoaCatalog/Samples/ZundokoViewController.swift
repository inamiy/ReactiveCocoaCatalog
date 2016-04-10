//
//  ZundokoViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-03-13.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa

private let _interval = 0.5

enum Zundoko
{
    case Zun
    case Doko
}

///
/// Example of chanting "Ki-yo-shi!!!" after "Zun, Zun Zun, Zun Doko".
///
/// - SeeAlso:
///   - [ズンドコキヨシ with RxSwift - Qiita](http://qiita.com/bricklife/items/4bf8c0e17043498f4452)
///   - [きよしのズンドコ節 / 氷川きよし - YouTube](https://www.youtube.com/watch?v=c0H_qGSJKzE)
///
class ZundokoViewController: UIViewController
{
    @IBOutlet weak var textView: UITextView?

    @IBOutlet weak var zunButton: UIButton?
    @IBOutlet weak var dokoButton: UIButton?

    var count = 0

    deinit { logDeinit(self) }

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
        let d = self.rac_deallocDisposable

        // Manual chanting of "Zun".
        let zun = zunButton!.rac_signalForControlEvents(.TouchUpInside).toSignalProducer()
            .map { _ in Zundoko.Zun }
            .ignoreCastError(NoError)

        // Manual chanting of "Doko".
        let doko = dokoButton!.rac_signalForControlEvents(.TouchUpInside).toSignalProducer()
            .map { _ in Zundoko.Doko }
            .ignoreCastError(NoError)

        d += timer(_interval, onScheduler: QueueScheduler.mainQueueScheduler)
            .map { _ in arc4random_uniform(2) == 0 ? Zundoko.Zun : .Doko }
            .mergeWith(zun)
            .mergeWith(doko)
            .on(next: { [weak self] zundoko in
                self?._printAll(zundoko)
            })
            .scan([]) { Array(($0 + [$1]).suffix(5)) } // collect 5 recent values
            .takeWhile { $0 != [.Zun, .Zun, .Zun, .Zun, .Doko] }  // "Zun, Zun Zun, Zun Doko..."
            .concat(
                // take a deep breath
                SignalProducer.empty
                    .delay(min(_interval, 1), onScheduler: QueueScheduler.mainQueueScheduler)
            )
            .on(completed: { [weak self] in
                // "Ki-yo-shi!!!"
                self?._printAll("\n＿人人 人人 人人＿\n" + "＞ Ki-yo-shi!!! ＜\n" + "￣Y^Y^Y^Y^Y^Y￣")
            })
            .forever()  // Kiyoshi forever
            .startWithInterrupted {
                print("Kiyoshi forever!!!") // called when forever-timer is safely disposed
            }
    }

    private func _printAll(message: Any)
    {
        self.count = self.count + 1
        print("\(self.count):", message)

        guard let textView = self.textView else { return }
        textView.text = (textView.text ?? "") + "\(self.count): \(message)\n"

        // scroll down to bottom
        textView.scrollRangeToVisible(NSRange(location: textView.text.characters.count - 1, length: 0))
    }

}
