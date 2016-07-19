//
//  WhoToFollowViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit
import ReactiveCocoa
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
class WhoToFollowViewController: UIViewController
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
        let refreshProducer = self.refreshButton!.rac_signalForControlEvents(.TouchUpInside).toSignalProducer()

        let fetchedUsersProducer = refreshProducer
            .beginWith("startup refresh")
            .ignoreCastError(SessionTaskError)
            .flatMap(.Merge) { _ in _randomUsersProducer() }

        func bindButton(button: UIButton)
        {
            let buttonTapProducer = button.rac_signalForControlEvents(.TouchUpInside).toSignalProducer()
                .beginWith("startup userButton")

            combineLatest(buttonTapProducer, fetchedUsersProducer.mapError { $0 as NSError })
                .map { _, users -> GitHubAPI.User? in
                    let randomIndex = Int(arc4random_uniform(UInt32(users.count)))
                    return users[randomIndex]
                }
                .mergeWith(refreshProducer.map { _ in nil })
                .beginWith(nil) // user = nil for emptying labels
                .ignoreError()
                .startWithNext { [weak button] user in

                    // update UI
                    button?.setTitle(user?.login, forState: .Normal)
                    button?.setImage(nil, forState: .Normal)

                    if let avatarURL = user?.avatarURL {
                        button?.hnk_setImageFromURL(avatarURL, state: .Normal)
                    }
                }
        }

        bindButton(self.user1Button!)
        bindButton(self.user2Button!)
        bindButton(self.user3Button!)

    }
}

private func _randomUsersProducer(since: Int = Int(arc4random_uniform(500))) -> SignalProducer<[GitHubAPI.User], SessionTaskError>
{
    let request = GitHubAPI.UsersRequest(since: since)
    return Session.responseProducer(request)
}
