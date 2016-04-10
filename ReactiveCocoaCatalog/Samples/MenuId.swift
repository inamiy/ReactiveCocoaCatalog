//
//  MenuId.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-09.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa
import FontAwesome

enum MenuId: Int
{
    case Friends    = 0
    case Chats      = 1
    case Home       = 2
    case Settings   = 3

    case Profile    = 10
    case Help       = 11

    static let allMenuIds = [0...3, 10...11].flatMap { $0.flatMap { MenuId(rawValue: $0) } }

    var fontAwesome: FontAwesome
    {
        switch self {
            case .Friends:  return .Users
            case .Chats:    return .Comment
            case .Home:     return .Home
            case .Settings: return .Gear
            case .Profile:  return .User
            case .Help:     return .Question
        }
    }

    var tabImage: UIImage
    {
        return UIImage.fontAwesomeIconWithName(
            self.fontAwesome,
            textColor: UIColor.blackColor(),
            size: CGSize(width: 40, height: 40)
        )
    }
}
