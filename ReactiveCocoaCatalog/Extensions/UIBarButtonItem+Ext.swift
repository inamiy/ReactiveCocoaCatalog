//
//  UIBarButtonItem+Ext.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-02.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import ReactiveCocoa

extension Reactive where Base: UIBarButtonItem
{
    /// Setup a default action that doesn't interact with `UIBarButton.enabled`
    /// for easily retrieving pressed `Signal`.
    public var defaultPressed: Signal<(), NoError>
    {
        guard self.pressed == nil else {
            return .empty
        }

        let defaultAction = Action<(), (), NoError> { _ in .init(value: ()) }
        self.pressed = CocoaAction(defaultAction)

        return defaultAction.values
    }
}
