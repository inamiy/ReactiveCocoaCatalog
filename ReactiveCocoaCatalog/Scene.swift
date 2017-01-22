//
//  Scene.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2017-01-22.
//  Copyright © 2017 Yasuhiro Inami. All rights reserved.
//

import UIKit

// MARK: Scene

public protocol Scene
{
    associatedtype VC: UIViewController
    func instantiate() -> VC
}

public struct NibScene<VC: UIViewController>: Scene
{
    public let nibName: String?
    public let bundle: Bundle?

    public init(nibName: String? = nil, bundle: Bundle? = nil)
    {
        self.nibName = nibName
        self.bundle = bundle
    }

    public func instantiate() -> VC
    {
        return VC(nibName: self.nibName, bundle: self.bundle)
    }
}

public struct StoryboardScene<VC: UIViewController>: Scene
{
    public let storyboardName: String
    public let controllerIdentifier: String?
    public let bundle: Bundle?

    public init(name: String, identifier: String? = String(describing: VC.self), bundle: Bundle? = nil)
    {
        self.storyboardName = name
        self.controllerIdentifier = identifier
        self.bundle = bundle
    }

    public func instantiate() -> VC
    {
        let storyboard = UIStoryboard(name: self.storyboardName, bundle: self.bundle)

        if let identifier = self.controllerIdentifier,
            let vc = storyboard.instantiateViewController(withIdentifier: identifier) as? VC
        {
            return vc
        }

        if let vc = storyboard.instantiateInitialViewController() as? VC {
            return vc
        }

        fatalError("`StoryboardScene.instantiate()` failed (storyboardName = \(storyboardName), controllerIdentifier = \(controllerIdentifier), bundle = \(bundle), castTo = `\(VC.self)`).")
    }
}

public struct AnyScene: Scene
{
    private let _instantiate: () -> UIViewController

    public init<S: Scene>(_ scene: S)
    {
        self._instantiate = scene.instantiate
    }

    public func instantiate() -> UIViewController
    {
        return self._instantiate()
    }
}

prefix operator *

/// Shortcut for creating `AnyScene` from `Scene`.
public prefix func * <S: Scene>(scene: S) -> AnyScene
{
    if let scene = scene as? AnyScene {
        return scene
    }
    return AnyScene(scene)
}

// MARK: SceneProvider

public protocol NibSceneProvider
{
    associatedtype VC: UIViewController
    static var nibScene: NibScene<VC> { get }
}

extension NibSceneProvider where Self: UIViewController
{
    // Default implementation.
    static var nibScene: NibScene<Self>
    {
        return NibScene<Self>(nibName: nil, bundle: nil)
    }
}

public protocol StoryboardSceneProvider
{
    associatedtype VC: UIViewController
    static var storyboardScene: StoryboardScene<VC> { get }
}

extension StoryboardSceneProvider where Self: UIViewController
{
    // Default implementation.
    static var storyboardScene: StoryboardScene<Self>
    {
        return StoryboardScene<Self>(name: String(describing: self))
    }
}
