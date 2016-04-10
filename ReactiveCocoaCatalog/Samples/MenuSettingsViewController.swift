//
//  MenuSettingsViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-09.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa

private let _cellIdentifier = "MenuSettingsCell"

final class MenuSettingsViewController: UITableViewController
{
    weak var menu: SettingsMenu?

    deinit { logDeinit(self) }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        guard let menu = self.menu else
        {
            fatalError("Required properties are not set.")
        }

        let menusChanged = menu.menusProperty.signal.triggerize()
        let badgeChanged = BadgeManager.badges.mergedSignal.triggerize()

        // `reloadData()` when menus or badges changed.
        menusChanged
            .mergeWith(badgeChanged)
            .observeNext { [weak self] _ in
                self?.tableView?.reloadData()
            }

        // Modal presentation & dismissal for serial execution.
        let modalAction = Action<MenuType, (), NoError> { [weak self] menu in
            return SignalProducer { observer, disposable in
                let modalVC = menu.viewController
                self?.presentViewController(modalVC, animated: true) {
                    scheduleAfterNow(1) {
                        self?.dismissViewControllerAnimated(true) {
                            observer.sendNext()
                            observer.sendCompleted()
                        }
                    }
                }
            }
        }

        // `tableView.didSelectRow()` handling
        self.rac_signalForSelector(Selector._didSelectRow.0, fromProtocol: Selector._didSelectRow.1)
            .toSignalProducer()
            .on(event: logSink("didSelectRow"))
            .ignoreCastError(NoError)
            .sampleFrom(self.menu!.menusProperty.producer)
            .map { racTuple, menus -> MenuType in
                let racTuple = racTuple as! RACTuple
                let indexPath = racTuple.second as! NSIndexPath
                let menu = menus[indexPath.row]
                return menu
            }
            .flatMap(.Merge) { menu in
                return modalAction.apply(menu)
                    .ignoreCastError(NoError)
            }
            .start()

        self.tableView.delegate = nil   // set nil to clear selector cache
        self.tableView.delegate = self
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.menu!.menusProperty.value.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(_cellIdentifier, forIndexPath: indexPath)

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
    private static let _didSelectRow: (Selector, Protocol) = (
        #selector(UITableViewDelegate.tableView(_:didSelectRowAtIndexPath:)),
        UITableViewDelegate.self
    )
}
