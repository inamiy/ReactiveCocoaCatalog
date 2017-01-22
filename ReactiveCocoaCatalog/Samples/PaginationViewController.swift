//
//  PaginationViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-03-21.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
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
class PaginationViewController: UITableViewController, StoryboardSceneProvider
{
    @IBOutlet weak var indicatorView: UIActivityIndicatorView?

    let viewModel = PaginationViewModel(
        paginationRequest: GitHubAPI.SearchRepositoriesRequest(query: "Swift")
    )

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let refreshButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: nil, action: nil)
        self.navigationItem.rightBarButtonItem = refreshButtonItem

        let refreshAction = Action<(), (), NoError> { _ in .init(value: ()) }
        refreshButtonItem.reactive.pressed = CocoaAction(refreshAction)

        refreshAction.values
            .observe(self.viewModel.refreshObserver)

        // NOTE: Requires KVO (DynamicProperty), not `rex_contentOffset`.
        DynamicProperty<CGPoint>(object: self.tableView, keyPath: #keyPath(UIScrollView.contentOffset)).signal
            .flatMap(.merge) { [weak self] _ -> SignalProducer<(), NoError> in
                self?.tableView._reachedBottom == true ? .init(value: ()) : .empty
            }
            .observe(self.viewModel.loadNextObserver)

        self.indicatorView!.reactive.isAnimating
            <~ self.viewModel.loading.producer

        self.viewModel.items.producer
            .startWithValues { [weak self] repositories in
                self?.tableView.reloadData()
            }

        // Trigger refresh manually.
        self.viewModel.refreshObserver.send(value: ())
    }
}

// MARK: UITableViewDataSource

extension PaginationViewController
{
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.viewModel.items.value.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: _cellIdentifier, for: indexPath)

        let repository = self.viewModel.items.value[indexPath.row]

        cell.textLabel?.text = repository.fullName
        cell.detailTextLabel?.text = "🌟\(repository.stargazersCount)"

        return cell
    }
}

// MARK: Helpers

extension UIScrollView
{
    fileprivate var _reachedBottom: Bool
    {
        let visibleHeight = frame.height - contentInset.top - contentInset.bottom
        let y = contentOffset.y + contentInset.top
        let threshold = max(0.0, contentSize.height - visibleHeight)

        return y > threshold ? true : false
    }
}
