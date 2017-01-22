//
//  AppDelegate.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit
import ReactiveSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    func _setupAppearance()
    {
        let font = UIFont(name: "AvenirNext-Medium", size: 16)!

        UINavigationBar.appearance().titleTextAttributes = [ NSFontAttributeName: font ]
        UIBarButtonItem.appearance().setTitleTextAttributes([ NSFontAttributeName: font ], for: .normal)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool
    {
        self._setupAppearance()

        let splitVC = self.window!.rootViewController as! UISplitViewController
        splitVC.delegate = self
        splitVC.preferredDisplayMode = .allVisible

        let mainNavC = splitVC.viewControllers[0] as! UINavigationController

        let mainVC = mainNavC.topViewController as! MasterViewController

        // NOTE: use dispatch_after to check `splitVC.collapsed` after delegation is complete (for iPad)
        // FIXME: look for better solution
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if !splitVC.isCollapsed {
                mainVC.showDetailViewController(at: 0)
            }
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool
    {
        return true
    }
}
