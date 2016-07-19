//
//  IncrementalSearchViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit
import ReactiveCocoa
import APIKit
import Argo

private let _cellIdentifier = "IncrementalSearchCellIdentifier"

class IncrementalSearchViewController: UITableViewController, UISearchBarDelegate
{
    var searchController: UISearchController?

    var bingSearchResponse: BingSearchResponse?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self

        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: _cellIdentifier)
        self.tableView.tableHeaderView = searchController.searchBar

        // workaround for iOS8
        // http://useyourloaf.com/blog/2015/04/26/search-bar-not-showing-without-a-scope-bar.html
        if !NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0))
        {
            searchController.searchBar.sizeToFit()
        }

        self.searchController = searchController

        let producer = searchController.searchBar.rac_textSignal.toSignalProducer()
            .ignoreCastError(SessionTaskError)
            .throttle(0.15, onScheduler: QueueScheduler.mainQueueScheduler)
            .flatMap(.Latest) { value -> SignalProducer<BingSearchResponse, SessionTaskError> in
                if let str = value as? String {
                    return BingAPI.searchProducer(str)
                }
                else {
                    return SignalProducer<BingSearchResponse, SessionTaskError>.empty
                }
            }
            .ignoreError()

        producer.startWithSignal { signal, disposable in
            signal.observeNext { [weak self] response in
                print("onNext = \(response)")
                self?.bingSearchResponse = response
                self?.tableView.reloadData()
            }
        }
    }

    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()

        // Workaround for UISearchController activated at wrong x-position
        // inside UISplitViewController (in iOS 9.3).
        // (Caveat: This is a hotfix and not perfect)
        if !(self.searchController?.searchBar.superview is UITableView) {
            self.searchController?.searchBar.superview?.frame.origin.x = 0
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.bingSearchResponse?.suggestions.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(_cellIdentifier, forIndexPath: indexPath)

        cell.textLabel?.text = self.bingSearchResponse?.suggestions[indexPath.row]

        return cell
    }
}
