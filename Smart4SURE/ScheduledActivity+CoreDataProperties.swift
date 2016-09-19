//
//  ScheduledActivity+CoreDataProperties.swift
//  Smart4SURE
//
//  Created by Shannon Young on 8/25/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ScheduledActivity {

    @NSManaged var expiresOn: Date?
    @NSManaged var finishedOn: Date?
    @NSManaged var guid: String?
    @NSManaged var persistent: NSNumber?
    @NSManaged var scheduledOn: Date?
    @NSManaged var startedOn: Date?
    @NSManaged var status: String?
    @NSManaged var taskIdentifier: String?
    @NSManaged var label: String?

}
