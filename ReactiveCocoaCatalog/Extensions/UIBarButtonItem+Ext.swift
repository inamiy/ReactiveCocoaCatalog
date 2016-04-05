//
//  UIBarButtonItem+Ext.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-02.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import ReactiveCocoa

private var _subjectKey: UInt8 = 0

extension UIBarButtonItem
{
    /// Easy UIBarButtonItem signal implementation in favor of verbosely setting RACCommand.
    /// - Note: Underlying signal is "hot".
    /// - SeeAlso: https://github.com/ReactiveCocoa/ReactiveCocoa/issues/993
    var rac_signal: RACSignal
    {
        return RACSignal.createSignal { [unowned self] subscriber in

            let newSubject = RACSubject()
            if let prevSubject = self.target as? RACSubject {
                newSubject.subscribe(prevSubject)
            }
            newSubject.subscribe(subscriber)
            objc_setAssociatedObject(self, &_subjectKey, newSubject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) // retain

            self.target = newSubject
            self.action = #selector(RACSubscriber.sendNext)

            self.rac_deallocDisposable.addDisposable(RACDisposable {
                subscriber.sendCompleted()
            })

            return RACDisposable { [weak self] in
                self?.target = nil
                self?.action = nil
            }

        }
    }
}
