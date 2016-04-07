//
//  UISearchBar+Ext.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import ReactiveCocoa

// http://spin.atomicobject.com/2014/02/03/objective-c-delegate-pattern/
// https://gist.github.com/eliperkins/9625856

extension UISearchBar: UISearchBarDelegate
{
    public var rac_textSignal: RACSignal
    {
        var signal = objc_getAssociatedObject(self, unsafeAddressOf(self)) as? RACSignal

        if signal == nil,
            let delegate = self.delegate as? NSObject
        {
            signal = delegate.rac_signalForSelector(#selector(UISearchBarDelegate.searchBar(_:textDidChange:)), fromProtocol: UISearchBarDelegate.self)
                .map { value in
                    let tuple = value as! RACTuple
                    return tuple.second
                }
        }

        objc_setAssociatedObject(self, unsafeAddressOf(self), signal, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        return signal!
    }
}
