//
//  MenuSettingsViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-09.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import ReactiveObjC
import ReactiveObjCBridge

private let _cellIdentifier = "MenuSettingsCell"

final class MenuSettingsViewController: UITableViewController, StoryboardSceneProvider
{
    static let storyboardScene = StoryboardScene<MenuSettingsViewController>(name: "MenuBadge")

    weak var menu: SettingsMenu?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        guard let menu = self.menu else
        {
            fatalError("Required properties are not set.")
        }

        let menusChanged = menu.menusProperty.signal.map { _ in () }
        let badgeChanged = BadgeManager.badges.mergedSignal.map { _ in () }

        // `reloadData()` when menus or badges changed.
        menusChanged
            .merge(with: badgeChanged)
            .observeValues { [weak self] _ in
                self?.tableView?.reloadData()
            }

        // Modal presentation & dismissal for serial execution.
        let modalAction = Action<MenuType, (), NoError> { [weak self] menu in
            return SignalProducer { observer, disposable in
                let modalVC = menu.viewController
                self?.present(modalVC, animated: true) {
                    _ = QueueScheduler.main.schedule(after: 1) {
                        self?.dismiss(animated: true) {
                            observer.send(value: ())
                            observer.sendCompleted()
                        }
                    }
                }
            }
        }

        // `tableView.didSelectRow()` handling
        bridgedSignalProducer(from: self.rac_signal(for: Selector._didSelectRow.0, from: Selector._didSelectRow.1))
            .on(event: logSink("didSelectRow"))
            .withLatest(from: self.menu!.menusProperty.producer)
            .map { racTuple, menus -> MenuType in
                let racTuple = racTuple as! RACTuple
                let indexPath = racTuple.second as! NSIndexPath
                let menu = menus[indexPath.row]
                return menu
            }
            .flatMap(.merge) { menu in
                return modalAction.apply(menu)
                    .ignoreCastError(NoError.self)
            }
            .start()

        self.tableView.delegate = nil   // set nil to clear selector cache
        self.tableView.delegate = self
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.menu!.menusProperty.value.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: _cellIdentifier, for: indexPath)

        let menu = self.menu!.menusProperty.value[indexPath.row]
        cell.textLabel?.text = "\(menu.menuId)"
        cell.detailTextLabel?.text = menu.badge.value.rawValue
        cell.imageView?.image = menu.tabImage.value

        return cell
    }
}

// MARK: Selectors

extension Selector
{
    // NOTE: needed to upcast to `Protocol` for some reason...
    fileprivate static let _didSelectRow: (Selector, Protocol) = (
        #selector(UITableViewDelegate.tableView(_:didSelectRowAt:)),
        UITableViewDelegate.self
    )
}
