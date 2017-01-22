//
//  ReactiveArrayViewControllerType.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-05.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import ReactiveObjC
import ReactiveObjCBridge
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
            let replaceButtonItem = self.replaceButtonItem,
            let removeButtonItem = self.removeButtonItem,
            let decrementButtonItem = self.decrementButtonItem,
            let incrementButtonItem = self.incrementButtonItem,
            let sectionOrItemButtonItem = self.sectionOrItemButtonItem else
        {
            assertionFailure("Storyboard UIs are not ready.")
            return
        }

        insertButtonItem.reactive.defaultPressed
            .withLatest(from: self.viewModel.sectionOrItem.producer)
            .map { $1 }
            .on(event: logSink("insertButtonItem"))
            .observeValues { [unowned self] mode, insertCount in
                guard insertCount > 0 else { return }

                switch mode {
                    case .section:
                        for _ in 1...insertCount {
                            let sectionCount = self.viewModel.sections.observableCount.value
                            let randomSection = Section.randomData()

                            self.viewModel.sections.insert(
                                randomSection,
                                at: random(sectionCount + 1)
                            )
                        }
                    case .item:
                        let sectionCount = self.viewModel.sections.observableCount.value
                        guard sectionCount > 0 else { break }

                        for _ in 1...insertCount {
                            let section = self.viewModel.sections[random(sectionCount)]
                            let itemCount = section.items.observableCount.value

                            section.items.insert(
                                Item.randomData(),
                                at: random(itemCount + 1)
                            )
                        }
                }
            }

        replaceButtonItem.reactive.defaultPressed
            .withLatest(from: self.viewModel.sectionOrItem.producer)
            .map { $1 }
            .on(event: logSink("replaceButtonItem"))
            .observeValues { [unowned self] mode, replaceCount in
                guard replaceCount > 0 else { return }

                switch mode {
                    case .section:
                        for _ in 1...replaceCount {
                            let sectionCount = self.viewModel.sections.observableCount.value
                            guard sectionCount > 0 else { break }

                            let randomSection = Section.randomData()

                            self.viewModel.sections.update(
                                randomSection,
                                at: random(sectionCount)
                            )
                        }
                    case .item:
                        let sectionCount = self.viewModel.sections.observableCount.value
                        guard sectionCount > 0 else { break }

                        for _ in 1...replaceCount {
                            let section = self.viewModel.sections[random(sectionCount)]
                            let itemCount = section.items.observableCount.value
                            guard itemCount > 0 else { break }

                            section.items.update(
                                Item.randomData(),
                                at: random(itemCount)
                            )
                        }
                }
            }

        removeButtonItem.reactive.defaultPressed
            .withLatest(from: self.viewModel.sectionOrItem.producer)
            .map { $1 }
            .on(event: logSink("removeButtonItem"))
            .observeValues { [unowned self] mode, removeCount in
                guard removeCount > 0 else { return }

                switch mode {
                    case .section:
                        for _ in 1...removeCount {
                            let sectionCount = self.viewModel.sections.observableCount.value
                            guard sectionCount > 0 else { break }

                            self.viewModel.sections.remove(at: random(sectionCount))
                        }
                    case .item:
                        let sectionCount = self.viewModel.sections.observableCount.value
                        guard sectionCount > 0 else { break }

                        for _ in 1...removeCount {
                            let section = self.viewModel.sections[random(sectionCount)]
                            let itemCount = section.items.observableCount.value
                            guard itemCount > 0 else { break }

                            section.items.remove(at: random(itemCount))
                        }
                }
            }

        let decrement = decrementButtonItem.reactive.defaultPressed
            .map { _ in -1 }
            .on(event: logSink("decrement"))

        let increment = incrementButtonItem.reactive.defaultPressed
            .map { _ in 1 }
            .on(event: logSink("increment"))

        let count = decrement.merge(with: increment)
            .withLatest(from: self.viewModel.sectionOrItem.producer)
            .map { max($1.1 + $0, 1) }

        let countProducer = SignalProducer(count)
            .prefix(value: 1)

        let sectionOrItem = sectionOrItemButtonItem.reactive.defaultPressed
            .withLatest(from: self.viewModel.sectionOrItem.producer)
            .map { $1.0.inverse }

        let sectionOrItemProducer = SignalProducer(sectionOrItem)
            .prefix(value: .section)
            .on(event: logSink("sectionOrItem"))

        decrementButtonItem.reactive.isEnabled
            <~ countProducer
                .map { $0 > 1 }

        //
        // Update `viewModel.sectionOrItem`.
        //
        // NOTE:
        // `count` is dependent on current `viewModel.sectionOrItem`,
        // so bind to it at last usage of `count`.
        //
        self.viewModel.sectionOrItem
            <~ SignalProducer.combineLatest(sectionOrItemProducer, countProducer)

        sectionOrItemButtonItem.reactive.title
            <~ self.viewModel.sectionOrItem.producer
                .map { "\($0.0.rawValue) \($0.1)" }     // e.g. "Section 1"

        // Update `tableView` sections.
        self.viewModel.changedSectionInfoSignal
            .observeValues(_updateSections(itemsView: self.itemsView))

        // Update `tableView` rows.
        self.viewModel.changedItemInfoSignal
            .observeValues(_updateItems(itemsView: self.itemsView))

        // Delete item (or section) via `didSelectItem`.
        bridgedSignalProducer(from: self.rac_signal(for: protocolSelectorForDidSelectItem.0, from: protocolSelectorForDidSelectItem.1))
            .on(event: logSink("didSelectRow"))
            .ignoreCastError(NoError.self)
            .startWithValues { [weak self] racTuple in
                let racTuple = racTuple as! RACTuple
                let indexPath = racTuple.second as! NSIndexPath

                guard let items = self?.viewModel.sections[indexPath.section].items else {
                    return
                }

                if items.count < 2 {
                    // delete section if last item
                    self?.viewModel.sections.remove(at: indexPath.section)
                }
                else {
                    // delete item
                    self?.viewModel.sections[indexPath.section].items.remove(at: indexPath.item)
                }
        }
    }

    func playDemo()
    {
        func delay(_ timeInterval: TimeInterval) -> SignalProducer<(), NoError>
        {
            return SignalProducer.empty
                .delay(timeInterval, on: QueueScheduler.main)
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
                    at: 0
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
                    at: 0
                )
            })
            .concat(delay(dt))
            .on(completed: {
                guard self.viewModel.sections.count > 0 else { return }

                print("*** sections.removeAtIndex ***")

                self.viewModel.sections.remove(at: 0)
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
                    at: 2
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
                    at: 2
                )
            })
            .concat(delay(dt))
            .on(completed: {
                guard self.viewModel.sections.count > 0 else { return }

                let section = self.viewModel.sections[0]
                guard section.items.count > 2 else { return }

                print("*** items.removeAtIndex ***")

                section.items.remove(at: 2)
            })
            .on(completed: {
                print("demo play end")
            })
            .start()
    }
}

// MARK: Helpers

private func _updateSections<ItemsView: ItemsViewType, Section: SectionType>(itemsView: ItemsView) -> (ChangedSectionInfo<Section>) -> ()
{
    return { [unowned itemsView] info in
        switch info.sectionOperation {
            case .append:
                let index = info.sectionCount - 1
                itemsView.insertSections([index], animationStyle: .fade)
            case let .insert(_, index):
                itemsView.insertSections([index], animationStyle: .fade)
            case let .update(_, index):
                itemsView.reloadSections([index], animationStyle: .fade)
            case let .remove(index):
                itemsView.deleteSections([index], animationStyle: .fade)
        }
    }
}

private func _updateItems<ItemsView: ItemsViewType, Item: ItemType>(itemsView: ItemsView) -> (ChangedItemInfo<Item>) -> ()
{
    return { [unowned itemsView] info in
        switch info.itemOperation {
            case .append:
                let index = info.itemCount - 1
                itemsView.insertItems(at: [IndexPath(row: index, section: info.sectionIndex)], animationStyle: .right)
            case let .insert(_, index):
                itemsView.insertItems(at: [IndexPath(row: index, section: info.sectionIndex)], animationStyle: .right)
            case let .update(_, index):
                itemsView.reloadItems(at: [IndexPath(row: index, section: info.sectionIndex)], animationStyle: .right)
            case let .remove(index):
                itemsView.deleteItems(at: [IndexPath(row: index, section: info.sectionIndex)], animationStyle: .right)
        }
    }
}
