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
        return [.coremotion, .localNotifications, .microphone]
    }
    
    override func presentOnboarding(for onboardingTaskType: SBAOnboardingTaskType) {
        // Since this app does not include a path for reconsent or login
        // should always show the onboarding view controller
        showOnboardingViewController(animated: true)
    }
    
    override func showOnboardingViewController(animated: Bool) {
        let vc = Smart4SUREOnboardingViewController()
        self.transition(toRootViewController: vc, state: .onboarding, animated: true)
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        
        // Listen for updates to the news feed
        NotificationCenter.default.addObserver(self, selector: #selector(newsfeedUpdated), name: NSNotification.Name(rawValue: SBANewsFeedUpdateNotificationKey), object: nil)
        newsfeedManager.fetchFeed(completion: nil)
    }
    
    override func applicationWillResignActive(_ application: UIApplication) {
        super.applicationWillResignActive(application)
        
        // remove notification listener
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: SBANewsFeedUpdateNotificationKey), object: nil)
    }
    
    lazy var newsfeedManager: SBANewsFeedManager = {
        return SBANewsFeedManager()
    }()
    
    func newsfeedUpdated(_ notification: Notification) {
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

