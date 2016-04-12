//
//  MenuCustomViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-09.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa
import FontAwesome

final class MenuCustomViewController: UIViewController
{
    @IBOutlet weak var mainLabel: UILabel?
    @IBOutlet weak var subLabel: UILabel?
    @IBOutlet weak var updateButton: UIButton?

    weak var menu: CustomMenu?

    deinit { logDeinit(self) }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        guard let menu = self.menu, mainLabel = self.mainLabel, subLabel = self.subLabel, updateButton = self.updateButton else
        {
            fatalError("Required properties are not set.")
        }

        mainLabel.font = UIFont.fontAwesomeOfSize(mainLabel.font.pointSize)

        mainLabel.rex_text
            <~ menu.title.producer
                .map { [unowned menu] title -> String in
                    let fontAwesome = menu.menuId.fontAwesome
                    var title2 = String.fontAwesomeIconWithName(fontAwesome)
                    title2.appendContentsOf(" \(title)")
                    return title2
                }

        subLabel.rex_text
            <~ menu.badge.producer
                .map { "Badge: \($0)" }

        BadgeManager.badges[menu.menuId]
            <~ updateButton.rac_signalForControlEvents(.TouchUpInside)
                .toSignalProducer()
                .ignoreCastError(NoError)
                .map { _ in Badge(rawValue: Badge.randomBadgeString()) }
    }
}
