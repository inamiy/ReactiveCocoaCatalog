//
//  MenuCustomViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-09.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import FontAwesome

final class MenuCustomViewController: UIViewController, StoryboardSceneProvider
{
    static let storyboardScene = StoryboardScene<MenuCustomViewController>(name: "MenuBadge")

    @IBOutlet weak var mainLabel: UILabel?
    @IBOutlet weak var subLabel: UILabel?
    @IBOutlet weak var updateButton: UIButton?

    weak var menu: CustomMenu?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        guard let menu = self.menu, let mainLabel = self.mainLabel, let subLabel = self.subLabel, let updateButton = self.updateButton else
        {
            fatalError("Required properties are not set.")
        }

        mainLabel.font = UIFont.fontAwesome(ofSize: mainLabel.font.pointSize)

        mainLabel.reactive.text
            <~ menu.title.producer
                .map { [unowned menu] title -> String in
                    let fontAwesome = menu.menuId.fontAwesome
                    var title2 = String.fontAwesomeIcon(name: fontAwesome)
                    title2.append(" \(title)")
                    return title2
                }

        subLabel.reactive.text
            <~ menu.badge.producer
                .map { "Badge: \($0)" }

        BadgeManager.badges[menu.menuId]
            <~ updateButton.reactive.controlEvents(.touchUpInside)
                .map { _ in Badge(rawValue: Badge.randomBadgeString()) }
    }
}
