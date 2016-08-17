//
//  AutomatonState.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-07-19.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Foundation
import Result
import ReactiveCocoa
import ReactiveAutomaton

enum AutomatonState: String, CustomStringConvertible
{
    case LoggedOut = "LoggedOut"
    case LoggingIn = "LoggingIn"
    case LoggedIn = "LoggedIn"
    case LoggingOut = "LoggingOut"

    var description: String { return self.rawValue }
}

/// - Note:
/// `LoginOK` and `LogoutOK` should only be used internally
/// (but Swift can't make them as `private case`)
enum AutomatonInput: String, CustomStringConvertible
{
    case Login = "Login"
    case LoginOK = "LoginOK"
    case Logout = "Logout"
    case LogoutOK = "LogoutOK"

    case ForceLogout = "ForceLogout"

    var description: String { return self.rawValue }
}
