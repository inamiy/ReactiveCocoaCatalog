//
//  IncrementalSearchViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import APIKit
import Argo

private let _cellIdentifier = "IncrementalSearchCellIdentifier"

class IncrementalSearchViewController: UITableViewController, UISearchBarDelegate, NibSceneProvider
{
    var searchController: UISearchController?

    var bingSearchResponse: BingSearchResponse?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: _cellIdentifier)
        self.tableView.tableHeaderView = searchController.searchBar

        // workaround for iOS8
        // http://useyourloaf.com/blog/2015/04/26/search-bar-not-showing-without-a-scope-bar.html
        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0))
        {
            searchController.searchBar.sizeToFit()
        }

        self.searchController = searchController

        let producer = searchController.searchBar.reactive.continuousTextValues
            .throttle(0.15, on: QueueScheduler.main)
            .flatMap(.latest) { value -> SignalProducer<BingSearchResponse, NoError> in
                if let str = value {
                    return BingAPI.searchProducer(query: str)
                        .ignoreCastError(NoError.self)
                }
                else {
                    return .empty
                }
            }

        producer.observeValues { [weak self] response in
            print("onNext = \(response)")
            self?.bingSearchResponse = response
            self?.tableView.reloadData()
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

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.bingSearchResponse?.suggestions.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: _cellIdentifier, for: indexPath)

        cell.textLabel?.text = self.bingSearchResponse?.suggestions[indexPath.row]

        return cell
    }
}
