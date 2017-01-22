//
//  ReactiveDataSourceType.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-04.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import ReactiveArray

/// - Note:
/// `Equatable` is required for evaluating appropriate `sectionIndex` in
/// `ReactiveDataSourceType.changedItemInfoSignal`.
public protocol SectionType: Equatable
{
    associatedtype Item: ItemType

    var items: ReactiveArray<Item> { get }
}

public protocol ItemType {}

public struct ChangedSectionInfo<Section: SectionType>
{
    let sectionOperation: ArrayOperation<Section>
    let sectionCount: Int
}

public struct ChangedItemInfo<Item: ItemType>
{
    let itemOperation: ArrayOperation<Item>
    let itemCount: Int
    let sectionIndex: Int
}

/// Base protocol for representing "section & item (row)" data-tree using `ReactiveArray`.
/// By default, `changedSectionInfoSignal` & `changedItemInfoSignal` will send
/// detailed changed information to work with UI, e.g. `UITableView`, `UICollectionView`.
public protocol ReactiveDataSourceType: class
{
    associatedtype Section: SectionType

    var sections: ReactiveArray<Section> { get }

    // MARK: Default implementation

    /// Helper signal triggered by `sections` change.
    var changedSectionInfoSignal: Signal<ChangedSectionInfo<Section>, NoError> { get }

    /// Helper signal triggered by `section.items` change.
    /// This signal also sends calculated `sectionIndex` from current `sections`'s state.
    var changedItemInfoSignal: Signal<ChangedItemInfo<Section.Item>, NoError> { get }
}

extension ReactiveDataSourceType
{
    public var changedSectionInfoSignal: Signal<ChangedSectionInfo<Section>, NoError>
    {
        return self.sections.signal
            .withLatest(from: self.sections.observableCount.producer)
            .map { ChangedSectionInfo(sectionOperation: $0, sectionCount: $1) }
    }

    public var changedItemInfoSignal: Signal<ChangedItemInfo<Section.Item>, NoError>
    {
        return self.sections.signal
            .flatMap(.merge) { operation -> Signal<ChangedItemInfo<Section.Item>, NoError> in
                guard let section = operation.value else {
                    return .empty
                }

                return section.items.signal
                    .withLatest(from: section.items.observableCount.producer)
                    .map { itemOperation, itemCount -> ChangedItemInfo<Section.Item>? in
                        guard let sectionIndex = self.sections.index(of: section) else { return nil }

                        return ChangedItemInfo<Section.Item>(itemOperation: itemOperation, itemCount: itemCount, sectionIndex: sectionIndex)
                    }
                    .skipNil()
            }
    }
}
