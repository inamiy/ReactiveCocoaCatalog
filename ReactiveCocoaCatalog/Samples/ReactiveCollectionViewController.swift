//
//  ReactiveCollectionViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-04.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa
import ReactiveArray

private let _cellIdentifier = "ReactiveCollectionViewCellIdentifier"
private let _headerIdentifier = "ReactiveCollectionHeaderViewIdentifier"

final class ReactiveCollectionViewController: UICollectionViewController, ReactiveArrayViewControllerType
{
    @IBOutlet weak var insertButtonItem: UIBarButtonItem?
    @IBOutlet weak var replaceButtonItem: UIBarButtonItem?
    @IBOutlet weak var removeButtonItem: UIBarButtonItem?

    @IBOutlet weak var decrementButtonItem: UIBarButtonItem?
    @IBOutlet weak var incrementButtonItem: UIBarButtonItem?
    @IBOutlet weak var sectionOrItemButtonItem: UIBarButtonItem?

    let viewModel = ReactiveArrayViewModel(cellIdentifier: _cellIdentifier, headerIdentifier: _headerIdentifier)

    let protocolSelectorForDidSelectItem = Selector._didSelectRow

    deinit { logDeinit(self) }

    var itemsView: UICollectionView
    {
        return self.collectionView!
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // show toolbar
        self.navigationController?.setToolbarHidden(false, animated: false)

        self.setupSignalsForDemo()

        self.itemsView.dataSource = self.viewModel

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
        #selector(UICollectionViewDelegate.collectionView(_:didSelectItemAtIndexPath:)),
        UICollectionViewDelegate.self
    )
}

// MARK: Subview UIs

final class ReactiveCollectionReusableView: UICollectionReusableView
{
    @IBOutlet weak var label: UILabel?
}

final class ReactiveCollectionViewCell: UICollectionViewCell
{
    @IBOutlet weak var label: UILabel?
}
