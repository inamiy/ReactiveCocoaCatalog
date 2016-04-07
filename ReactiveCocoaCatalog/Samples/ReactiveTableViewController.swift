//
//  ReactiveTableViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-02.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa
import ReactiveArray

private let _cellIdentifier = "ReactiveTableCellIdentifier"

final class ReactiveTableViewController: UITableViewController, ReactiveArrayViewControllerType
{
    @IBOutlet weak var insertButtonItem: UIBarButtonItem?
    @IBOutlet weak var replaceButtonItem: UIBarButtonItem?
    @IBOutlet weak var removeButtonItem: UIBarButtonItem?

    @IBOutlet weak var decrementButtonItem: UIBarButtonItem?
    @IBOutlet weak var incrementButtonItem: UIBarButtonItem?
    @IBOutlet weak var sectionOrItemButtonItem: UIBarButtonItem?

    let viewModel = ReactiveArrayViewModel(cellIdentifier: _cellIdentifier)

    let protocolSelectorForDidSelectItem = Selector._didSelectRow

    deinit { logDeinit(self) }

    var itemsView: UITableView
    {
        return self.tableView
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // show toolbar
        self.navigationController?.setToolbarHidden(false, animated: true)

        self.setupSignalsForDemo()

        self.tableView.dataSource = self.viewModel

        // Set delegate after calling `rac_signalForSelector(_:fromProtocol:)`.
        // - https://github.com/ReactiveCocoa/ReactiveCocoa/issues/1121
        // - http://stackoverflow.com/questions/22000433/rac-signalforselector-needs-empty-implementation
        self.itemsView.delegate = nil   // set nil to clear selector cache
        self.itemsView.delegate = self

        self.playDemo()
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
