//
//  Rex+Ext.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-12.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Rex

// MARK: Rex

// TODO: It might be a good idea to use Lens to put `initial` (getter) and `setter` together.

import Rex

private var backgroundColorKey: UInt8 = 0

extension UIView {
    /// Wraps a view's `backgroundColor` in a bindable property.
    public var rex_backgroundColor: MutableProperty<UIColor?> {
        return associatedProperty(self, key: &backgroundColorKey, initial: { $0.backgroundColor }, setter: { $0.backgroundColor = $1 })
    }
}

private var contentOffsetKey: UInt8 = 0

extension UIScrollView {
    /// Wraps a scroll view's `contentOffset` in a bindable property.
    public var rex_contentOffset: MutableProperty<CGPoint> {
        return associatedProperty(self, key: &contentOffsetKey, initial: { $0.contentOffset }, setter: { $0.contentOffset = $1 })
    }
}

private var titleKey: UInt8 = 0
private var imageKey: UInt8 = 0

extension UIBarItem {
    /// Wraps a bar item's `title` in a bindable property.
    public var rex_title: MutableProperty<String?> {
        return associatedProperty(self, key: &titleKey, initial: { $0.title }, setter: { $0.title = $1 })
    }

    /// Wraps a bar item's `image` in a bindable property.
    public var rex_image: MutableProperty<UIImage?> {
        return associatedProperty(self, key: &titleKey, initial: { $0.image }, setter: { $0.image = $1 })
    }
}

private var badgeValueKey: UInt8 = 0

extension UITabBarItem {
    /// Wraps a tab bar item's `badgeValue` in a bindable property.
    public var rex_badgeValue: MutableProperty<String?> {
        return associatedProperty(self, key: &titleKey, initial: { $0.badgeValue }, setter: { $0.badgeValue = $1 })
    }
}

private var viewControllerKey: UInt8 = 0
private var selectedIndexKey: UInt8 = 0

extension UITabBarController {
    /// Wraps a tab bar item's `badgeValue` in a bindable property.
    public var rex_viewControllers: MutableProperty<[UIViewController]?> {
        return associatedProperty(self, key: &viewControllerKey, initial: { $0.viewControllers }, setter: { $0.viewControllers = $1 })
    }

    /// Wraps a tab bar item's `selectedIndex` in a bindable property.
    public var rex_selectedIndex: MutableProperty<Int> {
        return associatedProperty(self, key: &selectedIndexKey, initial: { $0.selectedIndex }, setter: { $0.selectedIndex = $1 })
    }
}

private var animatingKey: UInt8 = 0

extension UIActivityIndicatorView
{
    public var rex_animating: MutableProperty<Bool> {
        return associatedProperty(self, key: &animatingKey, initial: { $0.stopAnimating(); return false }, setter: { $1 ? $0.startAnimating() : $0.stopAnimating() })
    }
}

// MARK: CoreAnimation

private var positionKey: UInt8 = 0
private var hiddenKey: UInt8 = 0

extension CALayer
{
    /// Wraps a layer's `position` value in a bindable property.
    public var rex_position: MutableProperty<CGPoint> {
        return associatedProperty(self, key: &positionKey, initial: { $0.position }, setter: { $0.position = $1 })
    }

    /// Wraps a layer's `hidden` state in a bindable property.
    public var rex_hidden: MutableProperty<Bool> {
        return associatedProperty(self, key: &hiddenKey, initial: { $0.hidden }, setter: { $0.hidden = $1 })
    }

    /// Wraps a layer's `backgroundColor` state in a bindable property.
    public var rex_backgroundColor: MutableProperty<CGColor?> {
        return associatedProperty(self, key: &backgroundColorKey, initial: { $0.backgroundColor }, setter: { $0.backgroundColor = $1 })
    }
}
