//
//  MenuId.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-09.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import FontAwesome

enum MenuId: Int
{
    case friends    = 0
    case chats      = 1
    case home       = 2
    case settings   = 3

    case profile    = 10
    case help       = 11

    static let allMenuIds = [0...3, 10...11].flatMap { $0.flatMap { MenuId(rawValue: $0) } }

    var fontAwesome: FontAwesome
    {
        switch self {
            case .friends:  return .users
            case .chats:    return .comment
            case .home:     return .home
            case .settings: return .gear
            case .profile:  return .user
            case .help:     return .question
        }
    }

    var tabImage: UIImage
    {
        return UIImage.fontAwesomeIcon(
            name: self.fontAwesome,
            textColor: UIColor.black,
            size: CGSize(width: 40, height: 40)
        )
    }
}
