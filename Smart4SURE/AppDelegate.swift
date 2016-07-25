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

}

