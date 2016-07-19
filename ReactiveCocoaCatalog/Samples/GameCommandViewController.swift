//
//  GameCommandViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-20.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa
import Rex

///
/// Street Fighter Super-Move-Command example.
///
/// - SeeAlso:
///   - [Street Fighter - Wikipedia, the free encyclopedia](https://en.wikipedia.org/wiki/Street_Fighter)
///
final class GameCommandViewController: UIViewController
{
    @IBOutlet var buttons: [UIButton]?
    @IBOutlet weak var effectLabel: UILabel?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let d = self.rac_deallocDisposable

        let buttonTaps = self.buttons!
            .map {
                $0.rac_signalForControlEvents(.TouchUpInside).toSignalProducer()
                    .map { $0 as? UIButton }
                    .ignoreCastError(NoError)
            }

        // NOTE: Commands are evaluated from button's title using easy IBOutletCollection.
        let commands = SignalProducer<SignalProducer<UIButton?, NoError>, NoError>(values: buttonTaps).flatten(.Merge)
            .map { GameCommand(rawValue: $0!.titleForState(.Normal)!) }
            .ignoreNil()
            .on(event: logSink("commands"))

        d += commands
            .promoteErrors(GameCommand.Error.self)
            .flatMap(.Latest) {
                SignalProducer(value: $0)
                    .concat(.never)
                    .timeoutWithError(.Timeout, afterInterval: 1, onScheduler: QueueScheduler.mainQueueScheduler)
            }
            .scan([]) { $0 + [$1] }
            .map { SuperMove(command: $0.map { $0.rawValue }.joinWithSeparator("")) }
            .ignoreNil()
            .take(1)
            .forever()
            .ignoreError()
            .startWithNext { [unowned self] command in
                print("\n＿人人 人人 人人＿\n" + "＞ \(command) ＜\n" + "￣Y^Y^Y^Y^Y^Y￣")
                _zoomOut(self.effectLabel!, text: "\(command)")
            }
    }
}

// MARK: GameCommand

enum GameCommand: String
{
//    case ➡️, ↘️, ⬇️, ↙️, ⬅️, ↖️, ⬆️, ↗️, 👊, 👣 // Comment-Out: Can't do this 😡💢

    // NOTE: Mapped to Storyboard labels.
    case Right = "➡️", DownRight = "↘️", Down = "⬇️", DownLeft = "↙️", Left = "⬅️", UpLeft = "↖️", Up = "⬆️", UpRight = "↗️"
    case Punch = "👊", Kick = "👣"
}

extension GameCommand
{
    enum Error: ErrorType
    {
        case Timeout
    }
}

// MARK: SuperMove

/// - SeeAlso: [Inputs - Street Fighter Wiki - Wikia](http://streetfighter.wikia.com/wiki/Inputs)
enum SuperMove: String
{
    case Hadouken = "⬇️↘️➡️👊"
    case Shoryuken = "➡️⬇️↘️👊"
    case TatsumakiSenpukyaku = "⬇️↙️⬅️👣" // a.k.a "Hurricane Kick"
    case ScrewPileDriver = "➡️↘️⬇️↙️⬅️↖️⬆️↗️👊"   // a.k.a. "Spinning Pile Driver"

    static let allValues = [Hadouken, Shoryuken, TatsumakiSenpukyaku, ScrewPileDriver]

    /// - Returns: Preferred `SuperMove` evaluated from `command` **suffix**.
    init?(command: String)
    {
        for value in SuperMove.allValues {
            if command.hasSuffix(value.rawValue) {
                self = value
                return
            }
        }

        return nil
    }
}

// MARK: Helpers

private func _zoomOut(label: UILabel, text: String)
{
    label.text = "\(text)"
    label.alpha = 1
    label.transform = CGAffineTransformIdentity

    UIView.animateWithDuration(0.5) {
        label.alpha = 0
        label.transform = CGAffineTransformMakeScale(3, 3)
    }
}
