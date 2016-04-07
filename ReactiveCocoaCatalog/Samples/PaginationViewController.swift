//
//  PaginationViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-03-21.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa
import APIKit
import Argo

private let _cellIdentifier = "PaginationCellIdentifier"

///
/// Pagination example.
///
/// - SeeAlso:
///   - https://github.com/tryswift/RxPagination
///
class PaginationViewController: UITableViewController
{
    @IBOutlet weak var indicatorView: UIActivityIndicatorView?

    let viewModel = PaginationViewModel(
        paginationRequest: GitHubAPI.SearchRepositoriesRequest(query: "Swift")
    )

    deinit { logDeinit(self) }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.racc_hookSelector(#selector(viewWillAppear(_:)))
            .start(self.viewModel.refreshPipe.1)

        let refreshButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: nil, action: nil)
        refreshButtonItem.rac_command = RACCommand.triggerCommand()
        self.navigationItem.rightBarButtonItem = refreshButtonItem

        refreshButtonItem.rac_command.executionSignals.toSignalProducer()
            .triggerize()
            .start(self.viewModel.refreshPipe.1)

        DynamicProperty(object: self.tableView, keyPath: "contentOffset").signal
            .flatMap(.Merge) { [weak self] _ -> SignalProducer<(), NoError> in
                self?.tableView._reachedBottom == true ? .init(value: ()) : .empty
            }
            .observe(self.viewModel.loadNextPipe.1)

        self.viewModel.loading.producer
            .startWithNext { [weak self] loading in
                if loading {
                    self?.indicatorView?.startAnimating()
                }
                else {
                    self?.indicatorView?.stopAnimating()
                }
            }

        self.viewModel.items.producer
            .startWithNext { [weak self] repositories in
                self?.tableView.reloadData()
            }
    }
}

// MARK: UITableViewDataSource

extension PaginationViewController
{
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.viewModel.items.value.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(_cellIdentifier, forIndexPath: indexPath)
        let repository = self.viewModel.items.value[indexPath.row]

        cell.textLabel?.text = repository.fullName
        cell.detailTextLabel?.text = "🌟\(repository.stargazersCount)"

        return cell
    }
}

// MARK: Helpers

extension UIScrollView
{
    private var _reachedBottom: Bool
    {
        let visibleHeight = frame.height - contentInset.top - contentInset.bottom
        let y = contentOffset.y + contentInset.top
        let threshold = max(0.0, contentSize.height - visibleHeight)

        return y > threshold ? true : false
    }
}
