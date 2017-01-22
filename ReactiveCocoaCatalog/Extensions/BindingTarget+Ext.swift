//
//  BindingTarget+Ext.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2017-01-22.
//  Copyright © 2017 Yasuhiro Inami. All rights reserved.
//

import UIKit
import ReactiveSwift

extension Reactive where Base: UIView {
    public var backgroundColor: BindingTarget<UIColor?> {
        return makeBindingTarget { $0.backgroundColor = $1 }
    }
}

extension Reactive where Base: CALayer {
    public var position: BindingTarget<CGPoint> {
        return makeBindingTarget { $0.position = $1 }
    }

    public var isHidden: BindingTarget<Bool> {
        return makeBindingTarget { $0.isHidden = $1 }
    }

    public var backgroundColor: BindingTarget<CGColor?> {
        return makeBindingTarget { $0.backgroundColor = $1 }
    }
}

extension Reactive where Base: UIBarItem {
    /// Sets the title of the barItem.
    public var title: BindingTarget<String?> {
        return makeBindingTarget { $0.title = $1 }
    }

    /// Sets the image of the barItem.
    public var image: BindingTarget<UIImage?> {
        return makeBindingTarget { $0.image = $1 }
    }
}

extension Reactive where Base: UITabBarItem {
    /// Sets the badgeValue of the tabBarItem.
    public var badgeValue: BindingTarget<String?> {
        return makeBindingTarget { $0.badgeValue = $1 }
    }
}

extension Reactive where Base: UITabBarController {
    public var viewControllers: BindingTarget<[UIViewController]?> {
        return makeBindingTarget { $0.viewControllers = $1 }
    }

    public var selectedIndex: BindingTarget<Int> {
        return makeBindingTarget { $0.selectedIndex = $1 }
    }
}
