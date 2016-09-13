//
//  Smart4SUREDashboardViewController.swift
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

class Smart4SUREDashboardViewController: SBAActivityTableViewController, SBAScheduledActivityDataSource, NSFetchedResultsControllerDelegate {
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Since this is a read-only table that is only changed while not visible on screen,
        // just fetch and reload the table.
        self.reloadData()
    }
    
    override var scheduledActivityDataSource: SBAScheduledActivityDataSource  {
        return self
    }
    
    var scheduledActivityManager: Smart4SUREScheduledActivityManager {
        return Smart4SUREScheduledActivityManager.sharedManager
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "ScheduledActivity")
        let sortDescriptor = NSSortDescriptor(key: "scheduledOn", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = NSPredicate(format: "(expiresOn <> NULL AND expiresOn < %@) OR (finishedOn <> NULL)", NSDate())
        
        let frc = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.scheduledActivityManager.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
    }()

    func reloadData() {
        // Always run on main thread
        dispatch_async(dispatch_get_main_queue()) {
            do {
                // perform the fetch
                try self.fetchedResultsController.performFetch()
                
                // reload table
                self.refreshControl?.endRefreshing()
                self.tableView.reloadData()
                
            } catch let error as NSError {
                print("Failed to fetch results: \(error)")
            }
        }
    }
    
    func numberOfSections() -> Int {
        guard let sections = fetchedResultsController.sections else { return 0 }
        return sections.count
    }
    
    func numberOfRowsInSection(section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else { return 1 }
        return sections[section].numberOfObjects > 0 ? sections[section].numberOfObjects : 1
    }

    func scheduledActivityAtIndexPath(indexPath: NSIndexPath) -> SBBScheduledActivity? {
        guard let mo = fetchedResultsController.objectAtIndexPath(indexPath) as? ScheduledActivity else { return nil }
        let schedule = SBBScheduledActivity()
        
        schedule.guid = mo.guid
        schedule.scheduledOn = mo.scheduledOn
        schedule.expiresOn = mo.expiresOn
        schedule.startedOn = mo.startedOn
        schedule.finishedOn = mo.finishedOn
        schedule.persistent = mo.persistent
        schedule.status = mo.status
        
        schedule.activity = SBBActivity()
        schedule.activity.label = mo.label
        if let finishedOn = mo.finishedOn {
            let format = NSLocalizedString("Completed: %@", comment: "Label for a completed activity")
            let dateString = NSDateFormatter.localizedStringFromDate(finishedOn, dateStyle: .ShortStyle, timeStyle: .ShortStyle)
            schedule.activity.labelDetail = String.localizedStringWithFormat(format, dateString)
        }
        else if let expiresOn = mo.expiresOn {
            let format = NSLocalizedString("Expired: %@", comment: "Label for a completed activity")
            let dateString = NSDateFormatter.localizedStringFromDate(expiresOn, dateStyle: .ShortStyle, timeStyle: .ShortStyle)
            schedule.activity.labelDetail = String.localizedStringWithFormat(format, dateString)
        }
        
        return schedule
    }
    
    func shouldShowTaskForIndexPath(indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func dequeueReusableCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
        guard let count = fetchedResultsController.sections?.first?.numberOfObjects where count > 0 else {
            tableView.separatorStyle = .None
            return tableView.dequeueReusableCellWithIdentifier("EmptyCell", forIndexPath: indexPath)
        }
        return super.dequeueReusableCell(tableView, indexPath: indexPath)
    }
    
    override func configureCell(cell: UITableViewCell, tableView: UITableView, indexPath: NSIndexPath) {
        super.configureCell(cell, tableView: tableView, indexPath: indexPath)
        guard let activityCell = cell as? SBAActivityTableViewCell else { return }
        
        // Always show the title cell color as black
        activityCell.titleLabel.textColor = UIColor.blackColor()
    }

}
