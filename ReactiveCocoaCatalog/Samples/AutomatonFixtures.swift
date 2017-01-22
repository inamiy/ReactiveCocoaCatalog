//
//  AutomatonState.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-07-19.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Foundation
import Result
import ReactiveSwift
import ReactiveAutomaton

enum AutomatonState: String
{
    case loggedOut
    case loggingIn
    case loggedIn
    case loggingOut
}

/// - Note:
/// `LoginOK` and `LogoutOK` should only be used internally
/// (but Swift can't make them as `private case`)
enum AutomatonInput: String
{
    case login
    case loginOK
    case logout
    case logoutOK

    case forceLogout
}
