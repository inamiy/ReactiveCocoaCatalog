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
    let class_: UIViewController.Type
    let storyboard: StoryboardScene<UIViewController>?
    let selected: Bool

    static func allCatalogs() -> [Catalog]
    {
        return [
            Catalog(
                title: "UITextField",
                description: "throttle()",
                class_: TextFieldViewController.self
            ),
            Catalog(
                title: "UITextField (Multiple)",
                description: "Login example",
                class_: MultipleTextFieldViewController.self
            ),
            Catalog(
                title: "Color Slider",
                description: "RGB Slider example",
                class_: ColorSliderViewController.self
            ),
            Catalog(
                title: "Who To Follow",
                description: "Suggestion box",
                class_: WhoToFollowViewController.self
            ),
            Catalog(
                title: "Incremental Search",
                description: "throttle + flatten(.Latest)",
                class_: IncrementalSearchViewController.self
            ),
            Catalog(
                title: "Action",
                description: "Action (CocoaAction & RACCommand) Example",
                class_: ActionViewController.self
            ),
            Catalog(
                title: "ZunDoko",
                description: "Zun, Zun Zun, Zun Doko, Kiyoshi!",
                class_: ZundokoViewController.self
            ),
            Catalog(
                title: "Pagination",
                description: "Pagination",
                class_: PaginationViewController.self,
                storyboard: StoryboardScene(
                    name: "PaginationViewController",
                    identifier: "PaginationViewController"
                )
            ),
            Catalog(
                title: "ReactiveArray (TableView)",
                description: "ReactiveArray + TableView",
                class_: ReactiveTableViewController.self,
                storyboard: StoryboardScene(
                    name: "ReactiveArray",
                    identifier: "ReactiveTableViewController"
                )
            ),
            Catalog(
                title: "ReactiveArray (CollectionView)",
                description: "ReactiveArray + CollectionView",
                class_: ReactiveCollectionViewController.self,
                storyboard: StoryboardScene(
                    name: "ReactiveArray",
                    identifier: "ReactiveCollectionViewController"
                )
            ),
            Catalog(
                title: "MenuBadge",
                description: "Tab + Badge",
                class_: MenuTabBarController.self,
                storyboard: StoryboardScene(
                    name: "MenuBadge",
                    identifier: "MenuTabBarController"
                )
            ),
            Catalog(
                title: "PhotosLike",
                description: "Photo Gallery + Like buttons",
                class_: PhotosViewController.self,
                storyboard: StoryboardScene(
                    name: "PhotosLike",
                    identifier: "PhotosViewController"
                ),
                selected: true
            ),
        ]
    }

    init(title: String?, description: String?, class_: UIViewController.Type, storyboard: StoryboardScene<UIViewController>? = nil, selected: Bool = false)
    {
        self.title = title
        self.description = description
        self.class_ = class_
        self.storyboard = storyboard
        self.selected = selected
    }
}

protocol Instantiateable
{
    associatedtype VC: UIViewController
    func instantiate() -> VC
}

struct StoryboardScene<VC: UIViewController>: Instantiateable
{
    let storyboardName: String
    let viewControllerIdentifier: String
    let bundle: NSBundle?

    init(name: String, identifier: String, bundle: NSBundle? = nil)
    {
        self.storyboardName = name
        self.viewControllerIdentifier = identifier
        self.bundle = bundle
    }

    func instantiate() -> VC
    {
        let storyboard = UIStoryboard(name: self.storyboardName, bundle: self.bundle)

        guard let vc = storyboard.instantiateViewControllerWithIdentifier(self.viewControllerIdentifier) as? VC else {
            fatalError("Couldn't cast to `\(VC.self)` while `StoryboardScene.instantiate()`.")
        }

        return vc
    }
}
