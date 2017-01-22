//
//  MenuManager.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-09.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Foundation
import Result
import ReactiveSwift
import FontAwesome

/// ViewModel for `MenuTabBarController`.
final class MenuManager
{
    let tabViewControllersProperty = MutableProperty<[UIViewController]>([])

    let menusProperty: Property<(main: [MenuType], sub: [MenuType])>
    private let _menusProperty = MutableProperty<(main: [MenuType], sub: [MenuType])>(main: [], sub: [])

    /// Dummy Menu API Action.
    let menuAction = Action<TimeInterval, MenuBadgeDummyAPI.MenuResponse, NoError> { input in
        return MenuBadgeDummyAPI._menusProducer(delay: input)
    }

    /// Dummy Badge API Action.
    let badgeAction = Action<TimeInterval, MenuBadgeDummyAPI.BadgeResponse, NoError> { input in
        return MenuBadgeDummyAPI._badgesProducer(delay: input)
    }

    init()
    {
        self.menusProperty = Property(self._menusProperty)

        // Update `_menusProperty` via Menu API.
        self._menusProperty <~ menuAction.values
            .map { menuIdsTuple in
                let main = menuIdsTuple.main.map(_createMenu)
                let sub = menuIdsTuple.sub.map(_createMenu)
                return (main, sub)
            }

        // Proxy for `tabC.viewControllers <~ _menusProperty`.
        self.tabViewControllersProperty <~ self._menusProperty.producer
            .map { $0.main.map { $0.viewController } }

        // Update on-memory badges via Badge API.
        for menuId in MenuId.allMenuIds {
            BadgeManager.badges[menuId] <~ self.badgeAction.values
                .map { badgeTuples -> Badge? in
                    return (badgeTuples.first { $0.menuId == menuId }?.badgeString)
                        .flatMap(Badge.init)
                }
                .skipNil()
        }

        // Bind to `menu.badge` everytime `_menusProperty` is updated.
        self._menusProperty.signal
            .map { $0 + $1 }  // main + sub
            .observeValues { menus in
                for menu in menus {
                    menu.badge <~ BadgeManager.badges[menu.menuId]
                }
            }

        /// Send subMenus to `SettingsMenu` everytime `_menusProperty` is updated.
        self._menusProperty.signal
            .flatMap(.merge) { main, sub -> SignalProducer<([MenuType], SettingsMenu), NoError> in
                if let x = (main + sub).find(SettingsMenu.self).map({ (sub, $0) }) {
                    return SignalProducer<([MenuType], SettingsMenu), NoError>(value: x).concat(.never)
                }
                else {
                    return .never
                }
            }
            .observeValues { subMenus, settingsMenu in
                settingsMenu.menusProperty.value = subMenus
            }
    }
}

// MARK: Dummy API

struct MenuBadgeDummyAPI
{
    typealias MenuResponse = (main: [MenuId], sub: [MenuId])
    typealias BadgeResponse = [(menuId: MenuId, badgeString: String)]

    /// Dummy response for layouting tabBar (main) and `Settings`'s tableView (sub).
    /// - Note: Main array has maximum of 5 elements, including `.Settings` at last.
    private static func _responseMenuIds() -> (main: [MenuId], sub: [MenuId])
    {
        var menuIds = MenuId.allMenuIds
        menuIds.remove(at: menuIds.index(of: .settings)!)
        menuIds.shuffle()
        let slices = splitAt(random(5))(menuIds)
        return (main: Array(slices.0 + [.settings]), sub: Array(slices.1))
    }

    /// Common SignalProducer for simulating dummy network calls with dummy network `delay`,
    /// which has response type `(main: [MenuId], sub: [MenuId])`.
    private static func _dummyResponseMenuIdsProducer(_ logContext: String, delay: TimeInterval) -> SignalProducer<MenuBadgeDummyAPI.MenuResponse, NoError>
    {
        return SignalProducer(value: MenuBadgeDummyAPI._responseMenuIds())
//            .on(started: logSink("dummy \(logContext) request"))
            .delay(delay, on: QueueScheduler.main)
//            .on(next: logSink("dummy \(logContext) response"))
    }

    /// SignalProducer for simulating `MenuList API` with dummy network `delay`
    /// which layouts mainMenus (tab) & subMenus (tableView).
    fileprivate static func _menusProducer(delay: TimeInterval) -> SignalProducer<MenuBadgeDummyAPI.MenuResponse, NoError>
    {
        return self._dummyResponseMenuIdsProducer("Menu API", delay: delay)
    }

    /// SignalProducer for simulating `Badge API` with dummy network `delay`
    /// which has response type `[(menuId: MenuId, badge: String)]` (menus are flattened).
    fileprivate static func _badgesProducer(delay: TimeInterval) -> SignalProducer<MenuBadgeDummyAPI.BadgeResponse, NoError>
    {
        return self._dummyResponseMenuIdsProducer("Badge API", delay: delay)
            .map { $0 + $1 } // flatten `main` & `sub`
            .map { menuIds in
                menuIds.map { ($0, Badge.randomBadgeString()) }
            }
    }
}

// MARK: Helpers

private func _createMenu(menuId: MenuId) -> MenuType
{
    switch menuId {
        case .settings:
            return SettingsMenu()
        default:
            return CustomMenu(menuId: menuId)
    }
}

/// For dummy Badge API.
extension Badge
{
    static func randomBadgeString() -> Swift.String
    {
        let rand = random(3000)
        let badgeString: Swift.String
        switch rand {
            case 0..<1500:
                badgeString = "\(rand)"
            case 1500..<2000:
                badgeString = "N"
            case 2000..<2500:
                badgeString = "ヽ(ツ)ﾉ"
            default:
                badgeString = ""
        }
        return badgeString
    }
}
