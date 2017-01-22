//
//  WhoToFollowViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import APIKit
import Haneke

///
/// Original demo:
///
/// - The introduction to Reactive Programming you've been missing"
///   https://gist.github.com/staltz/868e7e9bc2a7b8c1f754
///
/// - "Who to follow" Demo (JavaScript)
///   http://jsfiddle.net/staltz/8jFJH/48/
///
class WhoToFollowViewController: UIViewController, NibSceneProvider
{
    @IBOutlet var user1Button: UIButton?
    @IBOutlet var user2Button: UIButton?
    @IBOutlet var user3Button: UIButton?
    @IBOutlet var refreshButton: UIButton?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        self._setupButtons()
    }

    func _setupButtons()
    {
        let refreshProducer = SignalProducer(self.refreshButton!.reactive.controlEvents(.touchUpInside))
            .map { Optional($0) }

        let fetchedUsersProducer = refreshProducer
            .prefix(value: nil)   // startup refresh
            .flatMap(.merge) { _ in
                return _randomUsersProducer()
                    .ignoreCastError(NoError.self)
            }

        func bindButton(_ button: UIButton)
        {
            let buttonTapProducer = SignalProducer(button.reactive.controlEvents(.touchUpInside))
                .map { Optional($0) }
                .prefix(value: nil)    // startup userButton tap

            SignalProducer.combineLatest(buttonTapProducer, fetchedUsersProducer)
                .map { _, users -> GitHubAPI.User? in
                    return users[random(users.count)]
                }
                .merge(with: refreshProducer.map { _ in nil })
                .prefix(value: nil) // user = nil for emptying labels
                .startWithValues { [weak button] user in

                    // update UI
                    button?.setTitle(user?.login, for: .normal)
                    button?.setImage(nil, for: .normal)

                    if let avatarURL = user?.avatarURL {
                        button?.hnk_setImageFromURL(avatarURL, state: .normal)
                    }
                }
        }

        bindButton(self.user1Button!)
        bindButton(self.user2Button!)
        bindButton(self.user3Button!)

    }
}

private func _randomUsersProducer(since: Int = random(500)) -> SignalProducer<[GitHubAPI.User], SessionTaskError>
{
    let request = GitHubAPI.UsersRequest(since: since)
    return Session.responseProducer(request)
}
