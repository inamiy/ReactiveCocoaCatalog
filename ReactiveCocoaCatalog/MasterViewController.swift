//
//  MasterViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController
{
    let catalogs = Catalog.allCatalogs()
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
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
                self.showDetailViewControllerAtIndex(i)
                break
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
        return self.catalogs.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 

        let catalog = self.catalogs[indexPath.row]
        cell.textLabel?.text = catalog.title
        cell.detailTextLabel?.text = catalog.description
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        self.showDetailViewControllerAtIndex(indexPath.row)
    }
    
    func showDetailViewControllerAtIndex(index: Int)
    {
        let catalog = self.catalogs[index]
        
        let newVC: UIViewController = catalog.class_.init()
        let newNavC = UINavigationController(rootViewController: newVC)
        self.splitViewController?.showDetailViewController(newNavC, sender: self)
        
        newVC.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
        newVC.navigationItem.leftItemsSupplementBackButton = true
    }

}

