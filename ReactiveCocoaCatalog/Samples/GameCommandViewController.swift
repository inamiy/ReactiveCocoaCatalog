//
//  GameCommandViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-20.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift

///
/// Street Fighter Super-Move-Command example.
///
/// - SeeAlso:
///   - [Street Fighter - Wikipedia, the free encyclopedia](https://en.wikipedia.org/wiki/Street_Fighter)
///
final class GameCommandViewController: UIViewController, StoryboardSceneProvider
{
    static let storyboardScene = StoryboardScene<GameCommandViewController>(name: "GameCommand")

    @IBOutlet var buttons: [UIButton]?
    @IBOutlet weak var effectLabel: UILabel?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let buttonTaps = self.buttons!
            .map { $0.reactive.controlEvents(.touchUpInside) }

        // NOTE: Commands are evaluated from button's title using easy IBOutletCollection.
        let commands = SignalProducer<Signal<UIButton, NoError>, NoError>(buttonTaps).flatten(.merge)
            .map { GameCommand(rawValue: $0.title(for: .normal)!) }
            .skipNil()
            .on(event: logSink("commands"))

        let d = commands
            .promoteErrors(GameCommand.Error.self)
            .flatMap(.latest) {
                SignalProducer(value: $0)
                    .concat(.never)
                    .timeout(after: 1, raising: .timeout, on: QueueScheduler.main)
            }
            .scan([]) { $0 + [$1] }
            .map { SuperMove(command: $0.map { $0.rawValue }.joined(separator: "")) }
            .skipNil()
            .take(first: 1)
            .forever()
            .ignoreCastError(NoError.self)
            .startWithValues { [unowned self] command in
                print("\n＿人人 人人 人人＿\n" + "＞ \(command) ＜\n" + "￣Y^Y^Y^Y^Y^Y￣")
                _zoomOut(label: self.effectLabel!, text: "\(command)")
            }

        self.reactive.lifetime.ended.observeCompleted {
            d.dispose()
        }
    }
}

// MARK: GameCommand

enum GameCommand: String
{
//    case ➡️, ↘️, ⬇️, ↙️, ⬅️, ↖️, ⬆️, ↗️, 👊, 👣 // Comment-Out: Can't do this 😡💢

    // NOTE: Mapped to Storyboard labels.
    case right = "➡️", downRight = "↘️", down = "⬇️", downLeft = "↙️", left = "⬅️", upLeft = "↖️", up = "⬆️", upRight = "↗️"
    case punch = "👊", kick = "👣"
}

extension GameCommand
{
    enum Error: Swift.Error
    {
        case timeout
    }
}

// MARK: SuperMove

/// - SeeAlso: [Inputs - Street Fighter Wiki - Wikia](http://streetfighter.wikia.com/wiki/Inputs)
enum SuperMove: String
{
    case hadouken = "⬇️↘️➡️👊"
    case shoryuken = "➡️⬇️↘️👊"
    case tatsumakiSenpukyaku = "⬇️↙️⬅️👣" // a.k.a "Hurricane Kick"
    case screwPileDriver = "➡️↘️⬇️↙️⬅️↖️⬆️↗️👊"   // a.k.a. "Spinning Pile Driver"

    static let allValues = [hadouken, shoryuken, tatsumakiSenpukyaku, screwPileDriver]

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
    label.transform = CGAffineTransform.identity

    UIView.animate(withDuration: 0.5) {
        label.alpha = 0
        label.transform = CGAffineTransform(scaleX: 3, y: 3)
    }
}
