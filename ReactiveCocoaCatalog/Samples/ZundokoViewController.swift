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
    @IBOutlet var textView: UITextView?

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
        timer(_interval, onScheduler: QueueScheduler.mainQueueScheduler)
            .map { _ in arc4random_uniform(2) == 0 ? Zundoko.Zun : .Doko }
            .on(next: { [weak self] zundoko in
                self?._printAll(zundoko)
            })
            .scan([]) { Array(($0 + [$1]).suffix(5)) } // collect 5 recent values
            .takeWhile { $0 != [.Zun, .Zun, .Zun, .Zun, .Doko] }  // "Zun, Zun Zun, Zun Doko..."
            .concat(
                // take a deep breath
                SignalProducer.empty
                    .delay(_interval, onScheduler: QueueScheduler.mainQueueScheduler)
            )
            .on(completed: { [weak self] in
                // "Ki-yo-shi!!!"
                self?._printAll("\n＿人人 人人 人人＿\n" + "＞ Ki-yo-shi!!! ＜\n" + "￣Y^Y^Y^Y^Y^Y￣")
            })
            .times(2) // one more set
            .start()
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
