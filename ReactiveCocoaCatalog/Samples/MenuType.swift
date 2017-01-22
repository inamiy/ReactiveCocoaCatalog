//
//  BadgeMenu.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-09.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import FontAwesome

/// Transient menu protocol managed by `MenuManager`.
/// Conformed class is the **owner of `viewController`** and works as its viewModel.
protocol MenuType: class
{
    // Comment-Out: Let Swift make `[MenuType]` (type-erasure is cumbersome)
//    associatedtype VC: UIViewController

    var menuId: MenuId { get }
    var viewController: UIViewController { get }

    var title: MutableProperty<String> { get }
    var tabImage: MutableProperty<UIImage?> { get }
    var badge: MutableProperty<Badge> { get }
}

extension MenuType
{
    /// Helper method to bind to `viewController.tabBarItem`
    /// before `viewController.viewDidLoad()` (tabBarItem must be ready)
    /// but after `viewController.init()` (too early to access to **unowned viewModel**).
    func bindToTabBarItem()
    {
        self.viewController.tabBarItem.reactive.title <~ self.title.producer.map { $0 }
        self.viewController.tabBarItem.reactive.image <~ self.tabImage.producer.map { $0 }
        self.viewController.tabBarItem.reactive.badgeValue <~ self.badge.producer.map { $0.rawValue }
    }
}

/// ViewModel for `MenuSettingsViewController`, managed by `MenuManager`.
final class SettingsMenu: MenuType
{
    let menuId = MenuId.settings
    let viewController: UIViewController

    let title = MutableProperty<String>("\(MenuId.settings)")
    let tabImage: MutableProperty<UIImage?>
    let badge = MutableProperty<Badge>(.none)

    let menusProperty = MutableProperty<[MenuType]>([])

    init()
    {
        let vc = MenuSettingsViewController.storyboardScene.instantiate()

        self.viewController = vc
        self.tabImage = MutableProperty(self.menuId.tabImage)

        vc.menu = self

        self.bindToTabBarItem()
    }
}

/// ViewModel for `MenuCustomViewController`, managed by `MenuManager`.
final class CustomMenu: MenuType
{
    let menuId: MenuId
    let viewController: UIViewController

    let title: MutableProperty<String>
    let tabImage: MutableProperty<UIImage?>
    let badge = MutableProperty<Badge>(.none)

    init(menuId: MenuId)
    {
        let vc = MenuCustomViewController.storyboardScene.instantiate()

        self.menuId = menuId
        self.viewController = vc
        self.title = MutableProperty("\(menuId)")
        self.tabImage = MutableProperty(self.menuId.tabImage)

        vc.menu = self

        self.bindToTabBarItem()
    }
}
