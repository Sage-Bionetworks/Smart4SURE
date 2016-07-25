//
//  Smart4SUREPremissionsViewController.swift
//  Smart4SURE
//
//  Created by Shannon Young on 4/14/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import UIKit
import BridgeAppSDK

extension SBAPermissionsType {
    func permissionsTypeArray() -> [SBAPermissionsType] {
        let all: [SBAPermissionsType] = [.HealthKit,.Location,.LocalNotifications,.Coremotion,.Microphone,.Camera,.PhotoLibrary]
        return all.filter({ self.contains($0) })
    }
}

class Smart4SUREPermissionsViewController: UITableViewController, SBASharedInfoController {
    
    lazy var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.sharedApplication().delegate as! SBAAppInfoDelegate
    }()
    
    lazy var requiredPermissions: [SBAPermissionsType] = {
        return self.sharedAppDelegate.requiredPermissions.permissionsTypeArray()
    }()
    
    lazy var permissionsManager: SBAPermissionsManager! = {
       return SBAPermissionsManager.sharedManager()
    }()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requiredPermissions.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PermissionsCell", forIndexPath: indexPath)
        guard let permissionCell = cell as? Smart4SUREPermissionsCell else { return cell }
        
        let permissionType = requiredPermissions[indexPath.row]
        permissionCell.titleLabel.text = permissionsManager.permissionTitleForType(permissionType)
        permissionCell.detailLabel.text = permissionsManager.permissionDescriptionForType(permissionType)
        permissionCell.button.enabled = !permissionsManager.isPermissionsGrantedForType(permissionType)
        permissionCell.button.tag = indexPath.row
        
        return cell
    }
    
    @IBAction func buttonTapped(sender: UIButton) {
        let cellIndex = sender.tag
        let permissionType = requiredPermissions[cellIndex]
        permissionsManager.requestPermissionForType(permissionType) { [weak self] (granted, error) in
            if (granted) {
                guard let cell = self?.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: cellIndex, inSection: 0)) as? Smart4SUREPermissionsCell else {
                    return
                }
                cell.button.enabled = !granted
            }
            else if let error = error {
                let message = error.localizedBridgeErrorMessage
                self?.showAlertWithOk(nil, message: message, actionHandler: nil)
            }
        }
    }
    
    @IBAction func next(sender: AnyObject) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? SBABridgeAppSDKDelegate {
            appDelegate.showAppropriateViewController(true)
        }
    }
    
}

class Smart4SUREPermissionsCell : UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    
}