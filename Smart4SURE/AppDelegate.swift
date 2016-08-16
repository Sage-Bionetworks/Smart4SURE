//
//  AppDelegate.swift
//  Smart4SURE
//
//  Created by Shannon Young on 3/22/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
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
        guard let storyboard = openStoryboard("Onboarding"),
            let vc = storyboard.instantiateInitialViewController()
            else {
                assertionFailure("Failed to load onboarding storyboard")
                return
        }
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
}

