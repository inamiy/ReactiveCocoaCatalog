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

private let _reuseIdentifier = "reuseIdentifier"

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
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: _reuseIdentifier)
        self.tableView.tableHeaderView = searchController.searchBar
        
        // workaround for iOS8
        // http://useyourloaf.com/blog/2015/04/26/search-bar-not-showing-without-a-scope-bar.html
        if !NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)) {
            searchController.searchBar.sizeToFit()
        }
        
        self.searchController = searchController
        
        let producer = searchController.searchBar.rac_textSignal.toSignalProducer()
            .castErrorType(APIError)
            .throttle(0.15, onScheduler: QueueScheduler.mainQueueScheduler)
            .map { value -> SignalProducer<BingSearchResponse, APIError> in
                if let str = value as? String {
                    return BingAPI.searchProducer(str)
                }
                else {
                    return SignalProducer<BingSearchResponse, APIError>.empty
                }
            }
            .flatten(.Latest)
        
        producer.startWithSignal { signal, disposable in
            signal.observeNext { [weak self] response in
                print("onNext = \(response)")
                self?.bingSearchResponse = response
                self?.tableView.reloadData()
            }
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
        let cell = tableView.dequeueReusableCellWithIdentifier(_reuseIdentifier, forIndexPath: indexPath)
        
        cell.textLabel?.text = self.bingSearchResponse?.suggestions[indexPath.row]
        
        return cell
    }
}
