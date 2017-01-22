//
//  ReactiveArrayViewModel.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-02.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import ReactiveArray

// MARK: ReactiveArrayViewModel

///
/// Common viewModel for ReactiveArray demos,
/// which conforms to both `UITableViewDataSource` and `UICollectionViewDataSource`.
/// **For Demo Use Only.**
///
/// - Note:
/// Abstracting with new ViewModel-protocol and work with other existing protocols
/// e.g. `ReactiveDataSource` seems too difficult to implement, which is
/// probably the limitation of Swift 2's `associatedtype`-based, non-generic protocol.
///
final class ReactiveArrayViewModel: NSObject, ReactiveDataSourceType
{
    let sections = ReactiveArray<Section>()

    let sectionOrItem = MutableProperty<(SectionOrItem, Int)>(.section, 1)

    fileprivate let _cellIdentifier: String
    fileprivate let _headerIdentifier: String?

    init(cellIdentifier: String, headerIdentifier: String? = nil)
    {
        self._cellIdentifier = cellIdentifier
        self._headerIdentifier = headerIdentifier
    }
}

extension ReactiveArrayViewModel: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return self.sections.observableCount.value
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let section = self.sections[section]
        return section.items.observableCount.value
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: self._cellIdentifier, for: indexPath)

        cell.textLabel?.text = self.sections[indexPath.section][indexPath.row].title

        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete {
            let section = self.sections[indexPath.section]
            section.items.remove(at: indexPath.row)
        }
        else if editingStyle == .insert {

        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return self.sections[section].title
    }
}

extension ReactiveArrayViewModel: UICollectionViewDataSource
{
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return self.sections.observableCount.value
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        let section = self.sections[section]
        return section.items.observableCount.value
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self._cellIdentifier, for: indexPath) as! ReactiveCollectionViewCell

        cell.label?.text = self.sections[indexPath.section][indexPath.row].title

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
    {
        guard let headerIdentifier = self._headerIdentifier else {
            fatalError("`headerIdentifier` is missing in collectionView dataSource.")
        }

        let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerIdentifier, for: indexPath) as! ReactiveCollectionReusableView

        if kind == UICollectionElementKindSectionHeader {
            reusableView.label?.text = self.sections[indexPath.section].title
        }

        return reusableView
    }
}

// MARK: Section

struct Section: SectionType
{
    let title: String
    let items: ReactiveArray<Item>

    init(title: String, items: ReactiveArray<Item>)
    {
        self.title = title
        self.items = items
    }

    subscript(i: Int) -> Item
    {
        return self.items[i]
    }

    /// - Returns: 1 section with random `1...3` items.
    static func randomData() -> Section
    {
        let dateString = stringFromDate(Date())

        let items = ReactiveArray(elements: (0..<(random(3) + 1))
            .map { Item(title: "Item-\($0)") })

        return Section(title: "\(dateString)", items: items)
    }

    /// - Returns: 1 section with 0 item.
    static func emptyData() -> Section
    {
        let dateString = stringFromDate(Date())

        return Section(title: "\(dateString)", items: [])
    }
}

extension Section: Equatable {}

func == (lhs: Section, rhs: Section) -> Bool
{
    return lhs.title == rhs.title && lhs.items == rhs.items
}

// MARK: Item

struct Item: ItemType
{
    let title: String

    init(title: String)
    {
        self.title = title
    }

    static func randomData() -> Item
    {
        let dateString = stringFromDate(Date())

        return Item(title: "\(dateString)")
    }
}

// MARK: SectionOrItem (flag)

enum SectionOrItem: String, CustomStringConvertible
{
    case section = "Section"
    case item = "Item"

    var description: String
    {
        return self.rawValue
    }

    var inverse: SectionOrItem
    {
        switch self {
            case .section:  return .item
            case .item:     return .section
        }
    }
}
