//
//  Smart4SUREProfileViewController.swift
//  Smart4SURE
//
//  Created by Shannon Young on 4/13/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import UIKit
import BridgeAppSDK

let kOnsiteDataGroup = "onsite"

class Smart4SUREProfileViewController: UIViewController, SBASharedInfoController {
    
    lazy var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.sharedApplication().delegate as! SBAAppInfoDelegate
    }()
    
    var scheduledActivityManager: SBAScheduledActivityManager? {
        let viewController = parentViewController?.childViewControllers.mapAndFilter({ (vc) -> SBAActivityTableViewController? in
            if let navVC = vc as? UINavigationController, let avc = navVC.topViewController as? SBAActivityTableViewController {
                return avc
            }
            else if let avc = vc as? SBAActivityTableViewController {
                return avc
            }
            return nil
        }).first
        
        return viewController?.scheduledActivityManager
    }

    @IBOutlet weak var studyIdentifierLabel: UILabel!
    @IBOutlet weak var dataGroupsSwitch: UISwitch!
    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataGroupsSwitch.on = !sharedUser.containsDataGroup(kOnsiteDataGroup)
        studyIdentifierLabel.text = sharedUser.externalId
        
        let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString")
        versionLabel.text = "\(Localization.localizedAppName) \(version!), build \(NSBundle.mainBundle().appVersion())"
    }

    func isVisible() -> Bool {
        return self.tabBarController?.selectedViewController == self
    }
    
    @IBAction func dataGroupsSwitchChanged(sender: AnyObject) {
        
        let switchOn = dataGroupsSwitch.on
        dataGroupsSwitch.enabled = false
        func completionHandler(error: NSError?) {
            self.dataGroupsSwitch.enabled = true
            if let error = error {
                // if there was an error then handle it
                dataGroupsSwitch.on = !switchOn
                let title = AppLocalization.localizedString("PROFILE_VC_SWITCHING_SCHEDULE_FAILED")
                let message = error.localizedBridgeErrorMessage
                self.showAlertWithOk(title, message: message, actionHandler: nil)
            }
            else {
                scheduledActivityManager?.reloadData()
            }
        }
        
        if switchOn {
            // remove "onsite" data group
            sharedUser.removeDataGroup(kOnsiteDataGroup, completion: completionHandler)
        }
        else {
            // add "onsite" data group
            sharedUser.addDataGroup(kOnsiteDataGroup, completion: completionHandler)
        }
    }
    
    
}
