//
//  Smart4SURELearnViewController.swift
//  Smart4SURE
//
//  Created by Shannon Young on 4/12/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import UIKit
import BridgeAppSDK

class Smart4SURELearnViewController: UITableViewController {
    
    private let learnInfo : Smart4SURELearnInfo = Smart4SURELearnInfoPList()
    
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
        
        let cell = tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath)
        guard let item = self.itemForRowAtIndexPath(indexPath) else { return cell }
        
        cell.textLabel?.text = item.title
        
        let finder = SBAResourceFinder()
        cell.imageView?.image = finder.imageNamed(item.iconImage)
        
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
