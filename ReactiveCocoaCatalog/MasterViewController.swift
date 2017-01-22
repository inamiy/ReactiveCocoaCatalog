//
//  MasterViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit
import ReactiveSwift

class MasterViewController: UITableViewController
{
    let catalogs = Catalog.allCatalogs()

    override func awakeFromNib()
    {
        super.awakeFromNib()

        if UIDevice.current.userInterfaceIdiom == .pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // auto-select
        for i in 0..<self.catalogs.count {
            if self.catalogs[i].selected {
                self.showDetailViewController(at: i)
                break
            }
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.catalogs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let catalog = self.catalogs[indexPath.row]
        cell.textLabel?.text = catalog.title
        cell.detailTextLabel?.text = catalog.description

        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        self.showDetailViewController(at: indexPath.row)
    }

    func showDetailViewController(at index: Int)
    {
        let catalog = self.catalogs[index]

        let newVC = catalog.scene.instantiate()
        let newNavC = UINavigationController(rootViewController: newVC)
        self.splitViewController?.showDetailViewController(newNavC, sender: self)

        // Deinit logging.
        let message = deinitMessage(newVC)
        newVC.reactive.lifetime.ended.observeCompleted {
            print(message)
        }

        newVC.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
        newVC.navigationItem.leftItemsSupplementBackButton = true
    }

}
