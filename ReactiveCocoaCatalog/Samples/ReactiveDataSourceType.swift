//
//  ReactiveDataSourceType.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-04.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa
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
    let sectionOperation: Operation<Section>
    let sectionCount: Int
}

public struct ChangedItemInfo<Item: ItemType>
{
    let itemOperation: Operation<Item>
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
            .sampleFrom(self.sections.observableCount.producer)
            .map { ChangedSectionInfo(sectionOperation: $0, sectionCount: $1) }
    }

    public var changedItemInfoSignal: Signal<ChangedItemInfo<Section.Item>, NoError>
    {
        let changedItemInfoPipe = Signal<ChangedItemInfo<Section.Item>, NoError>.pipe()

        let observeItemChangeInSection: Section -> Disposable? = { [unowned self] section in
            return section.items.signal
                .sampleFrom(section.items.observableCount.producer)
                .observeNext { itemOperation, itemCount in
                    guard let sectionIndex = self.sections.indexOf(section) else { return }

                    let i = ChangedItemInfo<Section.Item>(itemOperation: itemOperation, itemCount: itemCount, sectionIndex: sectionIndex)
                    changedItemInfoPipe.1.sendNext(i)
            }
        }

        self.sections.signal
            .observeNext { operation in
                switch operation {
                    case let .Append(section):
                        observeItemChangeInSection(section)
                    case let .Insert(section, _):
                        observeItemChangeInSection(section)
                    case let .Update(section, _):
                        observeItemChangeInSection(section)
                    case .RemoveElement:
                        break   // do nothing
                }
            }

        return changedItemInfoPipe.0
    }
}
