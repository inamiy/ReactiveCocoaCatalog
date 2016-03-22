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
    let storyboard: Storyboard?
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
                description: "Action Example",
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
                storyboard: Storyboard(
                    name: "PaginationViewController",
                    identifier: "PaginationViewController"
                ),
                selected: true
            )
        ]
    }
    
    init(title: String?, description: String?, class_: UIViewController.Type, storyboard: Storyboard? = nil, selected: Bool = false)
    {
        self.title = title
        self.description = description
        self.class_ = class_
        self.storyboard = storyboard
        self.selected = selected
    }
}

struct Storyboard
{
    let storyboardName: String
    let viewControllerIdentifier: String

    init(name: String, identifier: String)
    {
        self.storyboardName = name
        self.viewControllerIdentifier = identifier
    }

    func instantiate() -> UIViewController
    {
        let storyboard = UIStoryboard(name: self.storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier(self.self.viewControllerIdentifier)
        return vc
    }
}
