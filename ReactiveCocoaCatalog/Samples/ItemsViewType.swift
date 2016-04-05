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

public typealias IndexPath = (section: Int, item: Int)

private func _indexPath(indexPath: IndexPath) -> NSIndexPath
{
    return NSIndexPath(forItem: indexPath.item, inSection: indexPath.section)
}

private func _indexSet(values: [Int]) -> NSIndexSet
{
    let indexSet = NSMutableIndexSet()
    for i in values {
        indexSet.addIndex(i)
    }
    return indexSet
}

/// Helper protocol to treat UITableView & UICollectionView in the same way.
public protocol ItemsViewType: class
{
    func insertItemsAtIndexPaths(paths: [IndexPath], animationStyle: UITableViewRowAnimation)
    func deleteItemsAtIndexPaths(paths: [IndexPath], animationStyle: UITableViewRowAnimation)
    func moveItemAtIndexPath(from: IndexPath, to: IndexPath)
    func reloadItemsAtIndexPaths(paths: [IndexPath], animationStyle: UITableViewRowAnimation)

    func insertSections(sections: [Int], animationStyle: UITableViewRowAnimation)
    func deleteSections(sections: [Int], animationStyle: UITableViewRowAnimation)
    func moveSection(from: Int, to: Int)
    func reloadSections(sections: [Int], animationStyle: UITableViewRowAnimation)
}

extension UITableView: ItemsViewType
{
    public func insertItemsAtIndexPaths(paths: [IndexPath], animationStyle: UITableViewRowAnimation)
    {
        self.insertRowsAtIndexPaths(paths.map(_indexPath), withRowAnimation: animationStyle)
    }

    public func deleteItemsAtIndexPaths(paths: [IndexPath], animationStyle: UITableViewRowAnimation)
    {
        self.deleteRowsAtIndexPaths(paths.map(_indexPath), withRowAnimation: animationStyle)
    }

    public func moveItemAtIndexPath(from: IndexPath, to: IndexPath)
    {
        self.moveRowAtIndexPath(_indexPath(from), toIndexPath: _indexPath(to))
    }

    public func reloadItemsAtIndexPaths(paths: [IndexPath], animationStyle: UITableViewRowAnimation)
    {
        self.reloadRowsAtIndexPaths(paths.map(_indexPath), withRowAnimation: animationStyle)
    }

    public func insertSections(sections: [Int], animationStyle: UITableViewRowAnimation)
    {
        self.insertSections(_indexSet(sections), withRowAnimation: animationStyle)
    }

    public func deleteSections(sections: [Int], animationStyle: UITableViewRowAnimation)
    {
        self.deleteSections(_indexSet(sections), withRowAnimation: animationStyle)
    }

    public func moveSection(from: Int, to: Int)
    {
        self.moveSection(from, toSection: to)
    }

    public func reloadSections(sections: [Int], animationStyle: UITableViewRowAnimation)
    {
        self.reloadSections(_indexSet(sections), withRowAnimation: animationStyle)
    }
}

extension UICollectionView: ItemsViewType
{
    public func insertItemsAtIndexPaths(paths: [IndexPath], animationStyle: UITableViewRowAnimation)
    {
        self.insertItemsAtIndexPaths(paths.map(_indexPath))
    }

    public func deleteItemsAtIndexPaths(paths: [IndexPath], animationStyle: UITableViewRowAnimation)
    {
        self.deleteItemsAtIndexPaths(paths.map(_indexPath))
    }

    public func moveItemAtIndexPath(from: IndexPath, to: IndexPath)
    {
        self.moveItemAtIndexPath(_indexPath(from), toIndexPath: _indexPath(to))
    }

    public func reloadItemsAtIndexPaths(paths: [IndexPath], animationStyle: UITableViewRowAnimation)
    {
        self.reloadItemsAtIndexPaths(paths.map(_indexPath))
    }

    public func insertSections(sections: [Int], animationStyle: UITableViewRowAnimation)
    {
        self.insertSections(_indexSet(sections))
    }

    public func deleteSections(sections: [Int], animationStyle: UITableViewRowAnimation)
    {
        self.deleteSections(_indexSet(sections))
    }

    public func moveSection(from: Int, to: Int)
    {
        self.moveSection(from, toSection: to)
    }

    public func reloadSections(sections: [Int], animationStyle: UITableViewRowAnimation)
    {
        self.reloadSections(_indexSet(sections))
    }
}
