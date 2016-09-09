//
//  Smart4SURELearnViewController.swift
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

class Smart4SURELearnViewController: UITableViewController , SBASharedInfoController {
    
    lazy var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.sharedApplication().delegate as! SBAAppInfoDelegate
    }()
    
    private let learnInfo : Smart4SURELearnInfo = Smart4SURELearnInfoPList()
    
    @IBOutlet weak var participantIDLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        participantIDLabel.text = sharedUser.externalId
        
        let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString")
        versionLabel.text = "\(Localization.localizedAppName) \(version!), build \(NSBundle.mainBundle().appVersion())"
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return learnInfo.count
    }
    
    func itemForRowAtIndexPath(indexPath: NSIndexPath) -> Smart4SURELearnItem? {
        guard let item = learnInfo[indexPath.row] else {
            assertionFailure("no learn item at index \(indexPath.row)")
            return nil
        }

        return item
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("LearnCell", forIndexPath: indexPath)
        guard let item = self.itemForRowAtIndexPath(indexPath) else { return cell }
        
        cell.textLabel?.text = item.title
        
        let finder = SBAResourceFinder()
        cell.imageView?.image = finder.imageNamed(item.iconImage)?.imageWithRenderingMode(.AlwaysTemplate)
        
        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if let cell = sender as? UITableViewCell,
           let indexPath = self.tableView.indexPathForCell(cell),
           let learnItem = self.itemForRowAtIndexPath(indexPath),
           let url = SBAResourceFinder().urlNamed(learnItem.details, withExtension:"html"),
           let vc = segue.destinationViewController as? SBAWebViewController {
            // Hook up the title and the url for the webview controller
            vc.title = learnItem.title
            vc.url = url
        }
    }
    
}

class LearnMoreTableViewCell: UITableViewCell {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let imageView = self.imageView {
            let originalCenter = imageView.center
            let originalFrame = imageView.frame
            let size: CGFloat = 27
            imageView.frame = CGRect(x: originalFrame.origin.x, y: originalCenter.y - size/2.0, width: size, height: size)
            
            var originalTextFrame = self.textLabel!.frame
            originalTextFrame.origin.x = CGRectGetMaxX(imageView.frame) + 16
            self.textLabel?.frame = originalTextFrame
        }
    }

}
