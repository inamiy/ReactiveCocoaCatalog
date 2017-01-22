//
//  Catalog.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit

struct Catalog
{
    let title: String?
    let description: String?
    let scene: AnyScene
    let selected: Bool

    static func allCatalogs() -> [Catalog]
    {
        return [
            Catalog(
                title: "UITextField",
                description: "throttle()",
                scene: *TextFieldViewController.nibScene
            ),
            Catalog(
                title: "UITextField (Multiple)",
                description: "Login example",
                scene: *MultipleTextFieldViewController.nibScene
            ),
            Catalog(
                title: "Color Slider",
                description: "RGB Slider example",
                scene: *ColorSliderViewController.nibScene
            ),
            Catalog(
                title: "Who To Follow",
                description: "Suggestion box",
                scene: *WhoToFollowViewController.nibScene
            ),
            Catalog(
                title: "Incremental Search",
                description: "throttle + flatten(.latest)",
                scene: *IncrementalSearchViewController.nibScene
            ),
            Catalog(
                title: "Action",
                description: "Action (CocoaAction & RACCommand) Example",
                scene: *ActionViewController.nibScene
            ),
            Catalog(
                title: "ZunDoko",
                description: "Zun, Zun Zun, Zun Doko, Kiyoshi!",
                scene: *ZundokoViewController.nibScene
            ),
            Catalog(
                title: "GameCommand",
                description: "⬇️↘️➡️👊 → Hadouken!!💥",
                scene: *GameCommandViewController.storyboardScene
            ),
            Catalog(
                title: "Pagination",
                description: "Pagination",
                scene: *PaginationViewController.storyboardScene
            ),
            Catalog(
                title: "ReactiveArray (TableView)",
                description: "ReactiveArray + TableView",
                scene: *ReactiveTableViewController.storyboardScene
            ),
            Catalog(
                title: "ReactiveArray (CollectionView)",
                description: "ReactiveArray + CollectionView",
                scene: *ReactiveCollectionViewController.storyboardScene
            ),
            Catalog(
                title: "MenuBadge",
                description: "Tab + Badge",
                scene: *MenuTabBarController.storyboardScene
            ),
            Catalog(
                title: "PhotosLike",
                description: "Photo Gallery + Like buttons",
                scene: *PhotosViewController.storyboardScene
            ),
            Catalog(
                title: "Automaton (StateMachine)",
                description: "State machine example",
                scene: *AutomatonViewController.storyboardScene
            )
        ]
    }

    init(title: String?, description: String?, scene: AnyScene, selected: Bool = false)
    {
        self.title = title
        self.description = description
        self.scene = scene
        self.selected = selected
    }
}
