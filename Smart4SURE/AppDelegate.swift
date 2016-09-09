//
//  AppDelegate.swift
//  Smart4SURE
//
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit
import BridgeAppSDK

@UIApplicationMain
class AppDelegate: SBAAppDelegate {
    
    override var requiredPermissions: SBAPermissionsType {
        return [.Coremotion, .LocalNotifications, .Microphone]
    }
    
    override func showMainViewController(animated: Bool) {
        guard let storyboard = openStoryboard("Main"),
            let vc = storyboard.instantiateInitialViewController()
            else {
                assertionFailure("Failed to load onboarding storyboard")
                return
        }
        self.transitionToRootViewController(vc, animated: animated)
    }
    
    override func showOnboardingViewController(animated: Bool) {
        let vc = Smart4SUREOnboardingViewController()
        self.transitionToRootViewController(vc, animated: animated)
    }
    
    func openStoryboard(name: String) -> UIStoryboard? {
        return UIStoryboard(name: name, bundle: nil)
    }
    
    override func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        
        #if DEBUG
            // modify the externalID and email and password to match the stored value
            // and setup for already signed in and consented.
            if let externalId = parseArguments("--testId:") where self.currentUser.externalId != externalId {
                self.currentUser.externalId = externalId
                let (email, password) = self.currentUser.emailAndPasswordForExternalId(externalId)
                self.currentUser.email = email
                self.currentUser.password = password
                self.currentUser.loginVerified = true
                self.currentUser.consentVerified = true
            }
            // Update the data groups (if needed)
            if let dataGroupsString = parseArguments("--dataGroups:") {
                let dataGroups = dataGroupsString.componentsSeparatedByString(",")
                if (self.currentUser.dataGroups == nil) || (dataGroups != self.currentUser.dataGroups!) {
                    self.currentUser.updateDataGroups(dataGroups, completion: nil)
                }
            }
        #endif
        
        return super.application(application, willFinishLaunchingWithOptions: launchOptions)
    }
    
    func parseArguments(prefix:String) -> String? {
        let args = NSProcessInfo.processInfo().arguments
        for arg in args {
            if arg.hasPrefix(prefix) {
                return arg.substringFromIndex(prefix.endIndex)
            }
        }
        return nil
    }
    
    override func applicationDidBecomeActive(application: UIApplication) {
        super.applicationDidBecomeActive(application)
        
        // Listen for updates to the news feed
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(newsfeedUpdated), name: SBANewsFeedUpdateNotificationKey, object: nil)
        newsfeedManager.fetchFeedWithCompletion(nil)
    }
    
    override func applicationWillResignActive(application: UIApplication) {
        super.applicationWillResignActive(application)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: SBANewsFeedUpdateNotificationKey, object: nil)
    }
    
    lazy var newsfeedManager: SBANewsFeedManager = {
        return SBANewsFeedManager()
    }()
    
    func newsfeedUpdated(notification: NSNotification) {
        updateNewsFeedBadge()
    }
    
    func updateNewsFeedBadge() {
        guard let tabController = window?.rootViewController as? UITabBarController,
            let tabItem = tabController.tabBar.items?.filter({ $0.tag == Smart4SURENewsfeedTableViewController.tabItemTag }).first
        else {
            return
        }
        
        let unreadCount = newsfeedManager.unreadPostsCount()
        tabItem.badgeValue = (unreadCount == 0) ? nil : "\(unreadCount)"
    }
    
}

