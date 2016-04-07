//
//  ReactiveArrayViewControllerType.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-05.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa
import ReactiveArray

/// Abstract interface for ReactiveArray demos.
/// **For Demo Use Only.**
protocol ReactiveArrayViewControllerType: class
{
    associatedtype ItemsView: UIView, ItemsViewType

    var itemsView: ItemsView { get }

    weak var insertButtonItem: UIBarButtonItem? { get }
    weak var replaceButtonItem: UIBarButtonItem? { get }
    weak var removeButtonItem: UIBarButtonItem? { get }

    weak var decrementButtonItem: UIBarButtonItem? { get }
    weak var incrementButtonItem: UIBarButtonItem? { get }
    weak var sectionOrItemButtonItem: UIBarButtonItem? { get }

    var viewModel: ReactiveArrayViewModel { get }

    var protocolSelectorForDidSelectItem: (Selector, Protocol) { get }

    func setupSignalsForDemo()
    func playDemo()
}

extension ReactiveArrayViewControllerType where Self: UIViewController
{
    func setupSignalsForDemo()
    {
        guard let insertButtonItem = self.insertButtonItem,
            replaceButtonItem = self.replaceButtonItem,
            removeButtonItem = self.removeButtonItem,
            decrementButtonItem = self.decrementButtonItem,
            incrementButtonItem = self.incrementButtonItem,
            sectionOrItemButtonItem = self.sectionOrItemButtonItem else
        {
            assertionFailure("Storyboard UIs are not ready.")
            return
        }

        insertButtonItem.rac_signal.toSignalProducer()
            .triggerize()
            .sampleFrom(self.viewModel.sectionOrItem.producer)
            .map { $1 }
            .on(event: logSink("insertButtonItem"))
            .startWithNext { [unowned self] mode, insertCount in
                guard insertCount > 0 else { return }

                switch mode {
                    case .Section:
                        for _ in 1...insertCount {
                            let sectionCount = self.viewModel.sections.observableCount.value
                            let randomSection = Section.randomData()

                            self.viewModel.sections.insert(
                                randomSection,
                                atIndex: random(sectionCount + 1)
                            )
                        }
                    case .Item:
                        let sectionCount = self.viewModel.sections.observableCount.value
                        guard sectionCount > 0 else { break }

                        for _ in 1...insertCount {
                            let section = self.viewModel.sections[random(sectionCount)]
                            let itemCount = section.items.observableCount.value

                            section.items.insert(
                                Item.randomData(),
                                atIndex: random(itemCount + 1)
                            )
                        }
                }
            }

        replaceButtonItem.rac_signal.toSignalProducer()
            .triggerize()
            .sampleFrom(self.viewModel.sectionOrItem.producer)
            .map { $1 }
            .on(event: logSink("replaceButtonItem"))
            .startWithNext { [unowned self] mode, replaceCount in
                guard replaceCount > 0 else { return }

                switch mode {
                    case .Section:
                        for _ in 1...replaceCount {
                            let sectionCount = self.viewModel.sections.observableCount.value
                            guard sectionCount > 0 else { break }

                            let randomSection = Section.randomData()

                            self.viewModel.sections.update(
                                randomSection,
                                atIndex: random(sectionCount)
                            )
                        }
                    case .Item:
                        let sectionCount = self.viewModel.sections.observableCount.value
                        guard sectionCount > 0 else { break }

                        for _ in 1...replaceCount {
                            let section = self.viewModel.sections[random(sectionCount)]
                            let itemCount = section.items.observableCount.value
                            guard itemCount > 0 else { break }

                            section.items.update(
                                Item.randomData(),
                                atIndex: random(itemCount)
                            )
                        }
                }
            }

        removeButtonItem.rac_signal.toSignalProducer()
            .triggerize()
            .sampleFrom(self.viewModel.sectionOrItem.producer)
            .map { $1 }
            .on(event: logSink("removeButtonItem"))
            .startWithNext { [unowned self] mode, removeCount in
                guard removeCount > 0 else { return }

                switch mode {
                    case .Section:
                        for _ in 1...removeCount {
                            let sectionCount = self.viewModel.sections.observableCount.value
                            guard sectionCount > 0 else { break }

                            self.viewModel.sections.removeAtIndex(random(sectionCount))
                        }
                    case .Item:
                        let sectionCount = self.viewModel.sections.observableCount.value
                        guard sectionCount > 0 else { break }

                        for _ in 1...removeCount {
                            let section = self.viewModel.sections[random(sectionCount)]
                            let itemCount = section.items.observableCount.value
                            guard itemCount > 0 else { break }

                            section.items.removeAtIndex(random(itemCount))
                        }
                }
            }

        let decrement = decrementButtonItem.rac_signal.toSignalProducer()
            .triggerize()
            .map { _ in -1 }
            .on(event: logSink("decrement"))

        let increment = incrementButtonItem.rac_signal.toSignalProducer()
            .triggerize()
            .map { _ in 1 }
            .on(event: logSink("increment"))

        let count = decrement.mergeWith(increment)
            .sampleFrom(self.viewModel.sectionOrItem.producer)
            .map { max($1.1 + $0, 1) }
            .beginWith(1)

        let sectionOrItem = sectionOrItemButtonItem.rac_signal.toSignalProducer()
            .triggerize()
            .sampleFrom(self.viewModel.sectionOrItem.producer)
            .map { $1.0.inverse }
            .beginWith(.Section)
            .on(event: logSink("sectionOrItem"))

        // Update `decrementButtonItem.enabled`.
        DynamicProperty(object: decrementButtonItem, keyPath: "enabled")
            <~ count
                .map { $0 > 1 }
                as SignalProducer<AnyObject?, NoError>

        //
        // Update `viewModel.sectionOrItem`.
        //
        // NOTE:
        // `count` is dependent on current `viewModel.sectionOrItem`,
        // so bind to it at last usage of `count`.
        //
        self.viewModel.sectionOrItem
            <~ combineLatest(sectionOrItem, count)

        // Update `sectionOrItemButtonItem.title`.
        DynamicProperty(object: sectionOrItemButtonItem, keyPath: "title")
            <~ self.viewModel.sectionOrItem.producer
                .map { "\($0.0.rawValue) \($0.1)" }     // e.g. "Section 1"
                as SignalProducer<AnyObject?, NoError>

        // Update `tableView` sections.
        self.viewModel.changedSectionInfoSignal
            .observeNext(_updateSections(self.itemsView))

        // Update `tableView` rows.
        self.viewModel.changedItemInfoSignal
            .observeNext(_updateItems(self.itemsView))

        // Delete item (or section) via `didSelectItem`.
        self.rac_signalForSelector(protocolSelectorForDidSelectItem.0, fromProtocol: protocolSelectorForDidSelectItem.1)
            .toSignalProducer()
            .on(event: logSink("didSelectRow"))
            .startWithNext { [weak self] racTuple in
                let racTuple = racTuple as! RACTuple
                let indexPath = racTuple.second as! NSIndexPath

                if self?.viewModel.sections[indexPath.section].items.count < 2 {
                    // delete section if last item
                    self?.viewModel.sections.removeAtIndex(indexPath.section)
                }
                else {
                    // delete item
                    self?.viewModel.sections[indexPath.section].items.removeAtIndex(indexPath.item)
                }
        }
    }

    func playDemo()
    {
        func delay(timeInterval: NSTimeInterval) -> SignalProducer<(), NoError>
        {
            return SignalProducer.empty
                .delay(timeInterval, onScheduler: QueueScheduler.mainQueueScheduler)
        }

        let t0 = 0.2    // initial delay
        let dt = 0.5    // interval

        delay(t0)
            .on(started: {
                print("demo play start")
            })
            .on(completed: {
                print("*** sections.append ***")

                self.viewModel.sections.append(
                    Section(title: "Section 1", items: [
                        Item(title: "title 1-0"),
                        Item(title: "title 1-1")
                    ])
                )
            })
            .concat(delay(dt))
            .on(completed: {
                print("*** sections.insert ***")

                self.viewModel.sections.insert(
                    Section(title: "Section 0", items: [
                        Item(title: "title 0-0"),
                        Item(title: "title 0-1"),
                        Item(title: "title 0-2")
                    ]),
                    atIndex: 0
                )
            })
            .concat(delay(dt))
            .on(completed: {
                guard self.viewModel.sections.count > 0 else { return }

                print("*** sections.update ***")

                self.viewModel.sections.update(
                    Section(title: "Section 0b", items: [
                        Item(title: "title 0-0b")
                    ]),
                    atIndex: 0
                )
            })
            .concat(delay(dt))
            .on(completed: {
                guard self.viewModel.sections.count > 0 else { return }

                print("*** sections.removeAtIndex ***")

                self.viewModel.sections.removeAtIndex(0)
            })
            .concat(delay(dt))
            .on(completed: {
                guard self.viewModel.sections.count > 0 else { return }

                let section = self.viewModel.sections[0]

                print("*** items.append ***")

                section.items.append(
                    Item(title: "title 1-2")
                )
            })
            .concat(delay(dt))
            .on(completed: {
                guard self.viewModel.sections.count > 0 else { return }

                let section = self.viewModel.sections[0]
                guard section.items.count > 2 else { return }

                print("*** items.insert ***")

                section.items.insert(
                    Item(title: "title 1-1.5"),
                    atIndex: 2
                )
            })
            .concat(delay(dt))
            .on(completed: {
                guard self.viewModel.sections.count > 0 else { return }

                let section = self.viewModel.sections[0]
                guard section.items.count > 2 else { return }

                print("*** items.update ***")

                section.items.update(
                    Item(title: "title 1-1.25"),
                    atIndex: 2
                )
            })
            .concat(delay(dt))
            .on(completed: {
                guard self.viewModel.sections.count > 0 else { return }

                let section = self.viewModel.sections[0]
                guard section.items.count > 2 else { return }

                print("*** items.removeAtIndex ***")

                section.items.removeAtIndex(2)
            })
            .on(completed: {
                print("demo play end")
            })
            .start()
    }
}

// MARK: Helpers

private func _updateSections<ItemsView: ItemsViewType, Section: SectionType>(itemsView: ItemsView) -> ChangedSectionInfo<Section> -> ()
{
    return { [unowned itemsView] info in
        switch info.sectionOperation {
            case .Append:
                let index = info.sectionCount - 1
                itemsView.insertSections([index], animationStyle: .Fade)
            case let .Insert(_, index):
                itemsView.insertSections([index], animationStyle: .Fade)
            case let .Update(_, index):
                itemsView.reloadSections([index], animationStyle: .Fade)
            case let .RemoveElement(index):
                itemsView.deleteSections([index], animationStyle: .Fade)
        }
    }
}

private func _updateItems<ItemsView: ItemsViewType, Item: ItemType>(itemsView: ItemsView) -> ChangedItemInfo<Item> -> ()
{
    return { [unowned itemsView] info in
        switch info.itemOperation {
            case .Append:
                let index = info.itemCount - 1
                itemsView.insertItemsAtIndexPaths([(info.sectionIndex, index)], animationStyle: .Right)
            case let .Insert(_, index):
                itemsView.insertItemsAtIndexPaths([(info.sectionIndex, index)], animationStyle: .Right)
            case let .Update(_, index):
                itemsView.reloadItemsAtIndexPaths([(info.sectionIndex, index)], animationStyle: .Right)
            case let .RemoveElement(index):
                itemsView.deleteItemsAtIndexPaths([(info.sectionIndex, index)], animationStyle: .Right)
        }
    }
}
