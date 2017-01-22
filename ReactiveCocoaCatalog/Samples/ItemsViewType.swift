//
//  ItemsViewType.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-02.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Foundation
import UIKit

// Ideas from https://github.com/RxSwiftCommunity/RxDataSources

/// Helper protocol to treat UITableView & UICollectionView in the same way.
public protocol ItemsViewType: class
{
    func insertItems(at indexPaths: [IndexPath], animationStyle: UITableViewRowAnimation)
    func deleteItems(at indexPaths: [IndexPath], animationStyle: UITableViewRowAnimation)
    func moveItem(from: IndexPath, to: IndexPath)
    func reloadItems(at indexPaths: [IndexPath], animationStyle: UITableViewRowAnimation)

    func insertSections(_ sections: [Int], animationStyle: UITableViewRowAnimation)
    func deleteSections(_ sections: [Int], animationStyle: UITableViewRowAnimation)
    func moveSection(from: Int, to: Int)
    func reloadSections(_ sections: [Int], animationStyle: UITableViewRowAnimation)
}

extension UITableView: ItemsViewType
{
    public func insertItems(at indexPaths: [IndexPath], animationStyle: UITableViewRowAnimation)
    {
        self.insertRows(at: indexPaths, with: animationStyle)
    }

    public func deleteItems(at indexPaths: [IndexPath], animationStyle: UITableViewRowAnimation)
    {
        self.deleteRows(at: indexPaths, with: animationStyle)
    }

    public func moveItem(from: IndexPath, to: IndexPath)
    {
        self.moveRow(at: from, to: to)
    }

    public func reloadItems(at indexPaths: [IndexPath], animationStyle: UITableViewRowAnimation)
    {
        self.reloadRows(at: indexPaths, with: animationStyle)
    }

    public func insertSections(_ sections: [Int], animationStyle: UITableViewRowAnimation)
    {
        self.insertSections(IndexSet(sections), with: animationStyle)
    }

    public func deleteSections(_ sections: [Int], animationStyle: UITableViewRowAnimation)
    {
        self.deleteSections(IndexSet(sections), with: animationStyle)
    }

    public func moveSection(from: Int, to: Int)
    {
        self.moveSection(from, toSection: to)
    }

    public func reloadSections(_ sections: [Int], animationStyle: UITableViewRowAnimation)
    {
        self.reloadSections(IndexSet(sections), with: animationStyle)
    }
}

extension UICollectionView: ItemsViewType
{
    public func insertItems(at indexPaths: [IndexPath], animationStyle: UITableViewRowAnimation)
    {
        self.insertItems(at: indexPaths)
    }

    public func deleteItems(at indexPaths: [IndexPath], animationStyle: UITableViewRowAnimation)
    {
        self.deleteItems(at: indexPaths)
    }

    public func moveItem(from: IndexPath, to: IndexPath)
    {
        self.moveItem(at: from, to: to)
    }

    public func reloadItems(at indexPaths: [IndexPath], animationStyle: UITableViewRowAnimation)
    {
        self.reloadItems(at: indexPaths)
    }

    public func insertSections(_ sections: [Int], animationStyle: UITableViewRowAnimation)
    {
        self.insertSections(IndexSet(sections))
    }

    public func deleteSections(_ sections: [Int], animationStyle: UITableViewRowAnimation)
    {
        self.deleteSections(IndexSet(sections))
    }

    public func moveSection(from: Int, to: Int)
    {
        self.moveSection(from, toSection: to)
    }

    public func reloadSections(_ sections: [Int], animationStyle: UITableViewRowAnimation)
    {
        self.reloadSections(IndexSet(sections))
    }
}
