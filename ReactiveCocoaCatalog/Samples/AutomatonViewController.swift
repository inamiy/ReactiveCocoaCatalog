//
//  AutomatonViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-07-18.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa
import Rex
import ReactiveAutomaton
import Pulsator

private typealias State = AutomatonState
private typealias Input = AutomatonInput

///
/// Automaton example.
///
/// - SeeAlso:
///   - https://github.com/inamiy/ReactiveAutomaton
///
class AutomatonViewController: UIViewController
{
    @IBOutlet weak var diagramView: UIImageView?
    @IBOutlet weak var label: UILabel?

    @IBOutlet weak var loginButton: UIButton?
    @IBOutlet weak var logoutButton: UIButton?
    @IBOutlet weak var forceLogoutButton: UIButton?

    private(set) var pulsator: Pulsator?

    private var _automaton: Automaton<State, Input>?

    deinit { logDeinit(self) }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let (textSignal, textObserver) = Signal<String?, NoError>.pipe()

        /// Count-up effect.
        func countUpProducer(status: String, count: Int = 4, interval: NSTimeInterval = 1, nextInput: Input) -> SignalProducer<Input, NoError>
        {
            return timer(interval)
                .take(count)
                .scan(0) { $0.0 + 1 }
                .prefix(value: 0)
                .map {
                    switch $0 {
                        case 0:     return "\(status)..."
                        case count: return "\(status) Done!"
                        default:    return "\(status)... (\($0))"
                    }
                }
                .on(next: textObserver.sendNext)
                .then(value: nextInput)
                .on(interrupted: logSink("\(status) interrupted"))
        }

        let loginOKProducer = countUpProducer("Login", nextInput: .LoginOK)
        let logoutOKProducer = countUpProducer("Logout", nextInput: .LogoutOK)
        let forceLogoutOKProducer = countUpProducer("ForceLogout", nextInput: .LogoutOK)

        // NOTE: predicate style i.e. `T -> Bool` is also available.
        let canForceLogout: State -> Bool = [.LoggingIn, .LoggedIn].contains

        /// Transition mapping.
        let mappings: [Automaton<State, Input>.NextMapping] = [

          /*  Input   |   fromState => toState     |      Effect       */
          /* ----------------------------------------------------------*/
            .Login    | .LoggedOut  => .LoggingIn  | loginOKProducer,
            .LoginOK  | .LoggingIn  => .LoggedIn   | .empty,
            .Logout   | .LoggedIn   => .LoggingOut | logoutOKProducer,
            .LogoutOK | .LoggingOut => .LoggedOut  | .empty,

            .ForceLogout | canForceLogout => .LoggingOut | forceLogoutOKProducer
        ]

        let (inputSignal, inputObserver) = Signal<Input, NoError>.pipe()

        let automaton = Automaton(
            state: .LoggedOut,
            input: inputSignal,
            mapping: reduce(mappings),
            strategy: .Latest   // NOTE: `.Latest` cancels previous running effect
        )
        self._automaton = automaton

        automaton.replies.observeNext { reply in
            print("received reply = \(reply)")
        }

        automaton.state.producer.startWithNext { state in
            print("current state = \(state)")
        }

        // Setup buttons.
        do {
            self.loginButton?.rac_signalForControlEvents(.TouchUpInside).toSignal()
                .ignoreError()
                .observeNext { _ in inputObserver.sendNext(.Login) }

            self.logoutButton?.rac_signalForControlEvents(.TouchUpInside).toSignal()
                .ignoreError()
                .observeNext { _ in inputObserver.sendNext(.Logout) }

            self.forceLogoutButton?.rac_signalForControlEvents(.TouchUpInside).toSignal()
                .ignoreError()
                .observeNext { _ in inputObserver.sendNext(.ForceLogout) }
        }

        // Setup label.
        do {
            self.label!.rex_text <~ textSignal
        }

        // Setup Pulsator.
        do {
            let pulsator = _createPulsator()
            self.pulsator = pulsator

            self.diagramView?.layer.addSublayer(pulsator)

            pulsator.rex_backgroundColor
                <~ automaton.state.producer
                    .map(_pulsatorColor)
                    .map { $0.CGColor }

            pulsator.rex_position
                <~ automaton.state.producer
                    .map(_pulsatorPosition)

            // Overwrite the pulsator color to red if `.ForceLogout` succeeded.
            pulsator.rex_backgroundColor
                <~ automaton.replies
                    .filter { $0.toState != nil && $0.input == .ForceLogout }
                    .map { _ in UIColor.redColor().CGColor }
        }

    }

}

// MARK: Pulsator

private func _createPulsator() -> Pulsator
{
    let pulsator = Pulsator()
    pulsator.numPulse = 5
    pulsator.radius = 100
    pulsator.animationDuration = 7
    pulsator.backgroundColor = UIColor(red: 0, green: 0.455, blue: 0.756, alpha: 1).CGColor

    pulsator.start()

    return pulsator
}

private func _pulsatorPosition(state: State) -> CGPoint
{
    switch state {
        case .LoggedOut:    return CGPoint(x: 40, y: 100)
        case .LoggingIn:    return CGPoint(x: 190, y: 20)
        case .LoggedIn:     return CGPoint(x: 330, y: 100)
        case .LoggingOut:   return CGPoint(x: 190, y: 180)
    }
}

private func _pulsatorColor(state: State) -> UIColor
{
    switch state {
        case .LoggedOut:
            return UIColor(red: 0, green: 0.455, blue: 0.756, alpha: 1)     // blue
        case .LoggingIn, .LoggingOut:
            return UIColor(red: 0.97, green: 0.82, blue: 0.30, alpha: 1)    // yellow
        case .LoggedIn:
            return UIColor(red: 0.50, green: 0.85, blue: 0.46, alpha: 1)    // green
    }
}
