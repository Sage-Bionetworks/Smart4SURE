//
//  OnboardingViewController.swift
//  Smart4SURE
//
//  Created by Shannon Young on 3/25/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import UIKit
import BridgeAppSDK
import ResearchKit

class Smart4SUREOnboardingViewController: UIViewController, SBAExternalIDOnboardingController, SBAKeyboardAnimator {
    
    lazy var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.sharedApplication().delegate as! SBAAppInfoDelegate
    }()
    
    @IBOutlet weak var registrationCodeTextField: UITextField!
    @IBOutlet weak var registrationButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var keyboardHeightLayoutConstraint: NSLayoutConstraint!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.navigationBarHidden = true
        
        self.handleViewDidAppear()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Smart4SUREOnboardingViewController.keyboardNotification(_:)), name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardNotification(notification: NSNotification) {
        self.keyboardChangedFrameNotification(notification)
    }
    
    @IBAction func registerUser(sender: AnyObject) {
        self.registerUser()
    }
    
    func goNext() {
        self.performSegueWithIdentifier("ShowPermissions", sender: self)
    }
    
}
