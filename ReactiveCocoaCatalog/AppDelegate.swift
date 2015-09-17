//
//  AppDelegate.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit
import ReactiveCocoa

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    
    func _setupAppearance()
    {
        let font = UIFont(name: "AvenirNext-Medium", size: 16)!
        
        UINavigationBar.appearance().titleTextAttributes = [ NSFontAttributeName : font ]
        UIBarButtonItem.appearance().setTitleTextAttributes([ NSFontAttributeName : font ], forState: .Normal)
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        self._setupAppearance()
        
        let splitVC = self.window!.rootViewController as! UISplitViewController
        splitVC.delegate = self
        
        let mainNavC = splitVC.viewControllers[0] as! UINavigationController
        
        let mainVC = mainNavC.topViewController as! MasterViewController
        
        // NOTE: use dispatch_after to check `splitVC.collapsed` after delegation is complete (for iPad)
        // FIXME: look for better solution
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1_000_000), dispatch_get_main_queue()) {
            if !splitVC.collapsed {
                mainVC.showDetailViewControllerAtIndex(0)
            }
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool
    {
        return true
    }
}

