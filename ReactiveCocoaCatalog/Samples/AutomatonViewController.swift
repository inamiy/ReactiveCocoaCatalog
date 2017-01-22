//
//  AutomatonViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-07-18.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
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
class AutomatonViewController: UIViewController, StoryboardSceneProvider
{
    static let storyboardScene = StoryboardScene<AutomatonViewController>(name: "Automaton")

    @IBOutlet weak var diagramView: UIImageView?
    @IBOutlet weak var label: UILabel?

    @IBOutlet weak var loginButton: UIButton?
    @IBOutlet weak var logoutButton: UIButton?
    @IBOutlet weak var forceLogoutButton: UIButton?

    private(set) var pulsator: Pulsator?

    private var _automaton: Automaton<State, Input>?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let (textSignal, textObserver) = Signal<String?, NoError>.pipe()

        /// Count-up effect.
        func countUpProducer(status: String, count: Int = 4, interval: TimeInterval = 1, nextInput: Input) -> SignalProducer<Input, NoError>
        {
            return timer(interval: .seconds(Int(interval)), on: QueueScheduler.main)
                .take(first: count)
                .scan(0) { $0.0 + 1 }
                .prefix(value: 0)
                .map {
                    switch $0 {
                        case 0:     return "\(status)..."
                        case count: return "\(status) Done!"
                        default:    return "\(status)... (\($0))"
                    }
                }
                .on(value: textObserver.send(value:))
                .then(value: nextInput)
                .on(interrupted: logSink("\(status) interrupted"))
        }

        let loginOKProducer = countUpProducer(status: "Login", nextInput: .loginOK)
        let logoutOKProducer = countUpProducer(status: "Logout", nextInput: .logoutOK)
        let forceLogoutOKProducer = countUpProducer(status: "ForceLogout", nextInput: .logoutOK)

        // NOTE: predicate style i.e. `T -> Bool` is also available.
        let canForceLogout: (State) -> Bool = [.loggingIn, .loggedIn].contains

        /// Transition mapping.
        let mappings: [Automaton<State, Input>.NextMapping] = [

          /*  Input   |   fromState => toState     |      Effect       */
          /* ----------------------------------------------------------*/
            .login    | .loggedOut  => .loggingIn  | loginOKProducer,
            .loginOK  | .loggingIn  => .loggedIn   | .empty,
            .logout   | .loggedIn   => .loggingOut | logoutOKProducer,
            .logoutOK | .loggingOut => .loggedOut  | .empty,

            .forceLogout | canForceLogout => .loggingOut | forceLogoutOKProducer
        ]

        let (inputSignal, inputObserver) = Signal<Input, NoError>.pipe()

        let automaton = Automaton(
            state: .loggedOut,
            input: inputSignal,
            mapping: reduce(mappings),
            strategy: .latest   // NOTE: `.latest` cancels previous running effect
        )
        self._automaton = automaton

        automaton.replies.observeValues { reply in
            print("received reply = \(reply)")
        }

        automaton.state.producer.startWithValues { state in
            print("current state = \(state)")
        }

        // Setup buttons.
        do {
            _ = self.loginButton?.reactive.controlEvents(.touchUpInside)
                .observeValues { _ in inputObserver.send(value: .login) }

            _ = self.logoutButton?.reactive.controlEvents(.touchUpInside)
                .observeValues { _ in inputObserver.send(value: .logout) }

            _ = self.forceLogoutButton?.reactive.controlEvents(.touchUpInside)
                .observeValues { _ in inputObserver.send(value: .forceLogout) }
        }

        // Setup label.
        do {
            self.label!.reactive.text <~ textSignal
        }

        // Setup Pulsator.
        do {
            let pulsator = _createPulsator()
            self.pulsator = pulsator

            self.diagramView?.layer.addSublayer(pulsator)

            pulsator.reactive.backgroundColor
                <~ automaton.state.producer
                    .map(_pulsatorColor)
                    .map { $0.cgColor }

            pulsator.reactive.position
                <~ automaton.state.producer
                    .map(_pulsatorPosition)

            // Overwrite the pulsator color to red if `.ForceLogout` succeeded.
            pulsator.reactive.backgroundColor
                <~ automaton.replies
                    .filter { $0.toState != nil && $0.input == .forceLogout }
                    .map { _ in UIColor.red.cgColor }
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
    pulsator.backgroundColor = UIColor(red: 0, green: 0.455, blue: 0.756, alpha: 1).cgColor

    pulsator.start()

    return pulsator
}

private func _pulsatorPosition(state: State) -> CGPoint
{
    switch state {
        case .loggedOut:    return CGPoint(x: 40, y: 100)
        case .loggingIn:    return CGPoint(x: 190, y: 20)
        case .loggedIn:     return CGPoint(x: 330, y: 100)
        case .loggingOut:   return CGPoint(x: 190, y: 180)
    }
}

private func _pulsatorColor(state: State) -> UIColor
{
    switch state {
        case .loggedOut:
            return UIColor(red: 0, green: 0.455, blue: 0.756, alpha: 1)     // blue
        case .loggingIn, .loggingOut:
            return UIColor(red: 0.97, green: 0.82, blue: 0.30, alpha: 1)    // yellow
        case .loggedIn:
            return UIColor(red: 0.50, green: 0.85, blue: 0.46, alpha: 1)    // green
    }
}
