//
//  MenuTabBarController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-09.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import ReactiveCocoa
import APIKit
import Argo

/// Tab + Badge example.
final class MenuTabBarController: UITabBarController, StoryboardSceneProvider
{
    static let storyboardScene = StoryboardScene<MenuTabBarController>(name: "MenuBadge")

    @IBOutlet weak var menuButton: UIButton?
    @IBOutlet weak var badgeButton: UIButton?

    let menuManager = MenuManager()

    // NOTE: CocoaAction must be retained to bind to UI
    var menuAction: CocoaAction<UIBarButtonItem>?
    var badgeAction: CocoaAction<UIBarButtonItem>?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let menuAction = CocoaAction<UIBarButtonItem>(self.menuManager.menuAction) { _ in 0.0 }
        let badgeAction = CocoaAction<UIBarButtonItem>(self.menuManager.badgeAction) { _ in 0.0 }

        self.menuAction = menuAction
        self.badgeAction = badgeAction

        // Add top-right navigation barButtonItems programatically.
        // Note that Storyboard (or even iOS Human Interface Guideline)
        // doesn't support "Nav > TabBar" controller stacks.
        let menuButtonItem = UIBarButtonItem(
            title: "Menu",
            style: .plain,
            target: menuAction,
            action: CocoaAction<UIBarButtonItem>.selector
        )
        let badgeButtonItem = UIBarButtonItem(
            title: "Badge",
            style: .plain,
            target: badgeAction,
            action: CocoaAction<UIBarButtonItem>.selector
        )
        self.navigationItem.rightBarButtonItems = [menuButtonItem, badgeButtonItem]

        let tabVCsChanged = self.menuManager.tabViewControllersProperty.signal

        self.reactive.viewControllers <~ tabVCsChanged.map { $0 }

        // Always select last tab (= `MenuId.Settings`) on change.
        self.reactive.selectedIndex <~ tabVCsChanged.map { $0.count - 1 }

        // Trigger Menu API manually so that random viewControllers will be set.
        self.menuManager.menuAction.apply(0.0).start()
    }
}
