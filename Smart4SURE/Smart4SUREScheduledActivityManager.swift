//
//  Smart4SUREScheduledActivityManager.swift
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
import BridgeSDK
import CoreData

class S4S: NSObject {
    
    static let kActivitySessionTaskId = "1-Combined"
    static let kTrainingSessionTaskId = "1-Training-Combined"
    static let kNumberOfDays = 3
    
    static let kComboPredicate = NSPredicate(format:"finishedOn = NULL AND taskIdentifier = %@", kActivitySessionTaskId)
    static let kTrainingPredicate = NSPredicate(format:"finishedOn = NULL AND taskIdentifier = %@", kTrainingSessionTaskId)
    static let kActiveTaskPredicate = NSPredicate(format:"taskIdentifier = %@ OR taskIdentifier = %@", kActivitySessionTaskId, kTrainingSessionTaskId)
}

class Smart4SUREScheduledActivityManager: SBAScheduledActivityManager {
    
    static let sharedManager = Smart4SUREScheduledActivityManager()
    
    override init() {
        super.init()
        self.sections = [.expiredYesterday, .today, .keepGoing, .comingUp]
    }
    
    override func load(scheduledActivities: [SBBScheduledActivity]) {
        // cache the schedules beofre filtering
        updateSchedules(scheduledActivities)
        // Filter the schedules before passing to super
        let schedules = filterSchedules(scheduledActivities)
        super.load(scheduledActivities: schedules)
    }
    
    override func messageForUnavailableSchedule(_ schedule: SBBScheduledActivity) -> String {
        guard schedule.taskIdentifier == S4S.kActivitySessionTaskId, let endTime = schedule.expiresTime else {
            return super.messageForUnavailableSchedule(schedule)
        }
        let format = NSLocalizedString("This activity is available from %@ until %@ for %@ days. You only need to complete the activity on one of the available days" , comment: "")
        let numberOfDays = NumberFormatter.localizedString(from: NSNumber(value: S4S.kNumberOfDays as Int), number: .spellOut)
        return String.localizedStringWithFormat(format, schedule.scheduledTime, endTime, numberOfDays)
    }
    
    func filterSchedules(_ scheduledActivities: [SBBScheduledActivity]) -> [SBBScheduledActivity] {
        
        // Take the schedules and copy them to a new array, spliting the "Activity Session" schedule
        // over 3 days. If there are more than one split schedule, then only include the first.
        var allSchedules: [SBBScheduledActivity] = []
        var splitScheduleFound: Bool = false
        for schedule in scheduledActivities {
            let schedules = splitSchedule(schedule)
            if !splitScheduleFound || schedules.count == 1 {
                allSchedules.append(contentsOf: schedules)
                splitScheduleFound = splitScheduleFound || (schedules.count > 1)
            }
        }
        
        return allSchedules
    }
    
    func splitSchedule(_ schedule: SBBScheduledActivity) -> [SBBScheduledActivity] {
    
        // If this is not a combo schedule then return the schedule
        guard S4S.kComboPredicate.evaluate(with: schedule) else { return [schedule] }
        
        // Split the schedule into three days
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        var scheduleMidnightDate = calendar.startOfDay(for: schedule.scheduledOn)
        var scheduledOnComponents = (calendar as NSCalendar).components([.hour, .minute], from: schedule.scheduledOn)
        var expiredOnComponents = (calendar as NSCalendar).components([.hour, .minute], from: schedule.expiresOn)
        
        var activities: [SBBScheduledActivity] = []
        for _ in 0 ..< S4S.kNumberOfDays {
        
            // Pull the date for 3 days in a row and union with the time for start/end
            // Need to check the year/month/day because these can cross calendar boundaries
            let dateComponents = (calendar as NSCalendar).components([.year, .month, .day], from: scheduleMidnightDate)
            
            scheduledOnComponents.year = dateComponents.year
            scheduledOnComponents.month = dateComponents.month
            scheduledOnComponents.day = dateComponents.day
            
            expiredOnComponents.year = dateComponents.year
            expiredOnComponents.month = dateComponents.month
            expiredOnComponents.day = dateComponents.day
            
            // Modify the scheduled time and detail
            let activity = schedule.copy() as! SBBScheduledActivity
            activity.scheduledOn = calendar.date(from: scheduledOnComponents)
            activity.expiresOn = calendar.date(from: expiredOnComponents)
            
            // Add to the list
            activities.append(activity)
            
            // Forward the date by 1 day
            scheduleMidnightDate = scheduleMidnightDate.addingTimeInterval(24 * 60 * 60)
        }
        
        return activities
    }
    
    
    // MARK: - Update schedule
    
    func updateSchedules(_ scheduledActivities: [SBBScheduledActivity]) {
        
        let schedules = scheduledActivities.sorted(by: { $0.0.guid > $0.1.guid })
        guard schedules.count > 0 else { return }
        
        let context = backgroundObjectContext
        context.perform {
            
            let fetchRequest: NSFetchRequest<ScheduledActivity> = {
                if #available(iOS 10.0, *) {
                     return ScheduledActivity.fetchRequest() as! NSFetchRequest<ScheduledActivity>
                } else {
                    return NSFetchRequest(entityName: "ScheduledActivity")
                }
            }()
            fetchRequest.predicate = NSPredicate(format: "guid IN %@", schedules.map({ $0.guid }))
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "guid", ascending: true)]
            
            do {
    
                let fetchedSchedules = try context.fetch(fetchRequest)
                for schedule in schedules {
                    
                    // Get or insert the managed object
                    let mo: ScheduledActivity = {
                        // Note: this kind of filtering is very inefficient, but since we are only dealing
                        // with a few results, should be fine.
                        if let fetchedSchedule = fetchedSchedules.filter({ $0.guid == schedule.guid }).first {
                            return fetchedSchedule
                        }
                        else {
                            return NSManagedObject(entity: fetchRequest.entity!, insertInto: context) as! ScheduledActivity
                        }
                    }()
                
                    // Update the object
                    mo.taskIdentifier = schedule.taskIdentifier
                    mo.guid = schedule.guid
                    mo.scheduledOn = schedule.scheduledOn
                    mo.expiresOn = schedule.expiresOn
                    mo.startedOn = schedule.startedOn
                    mo.finishedOn = schedule.finishedOn
                    mo.persistent = schedule.persistent
                    mo.status = schedule.status
                    mo.label = schedule.activity.label
                }
            
                // Save
                try context.save()
                
            } catch let error as NSError {
                assertionFailure("Error merging schedules: \(error.localizedFailureReason)")
                context.rollback()
            }
        }
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "org.sagebase.CoreData" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let bundle = Bundle.main
        let modelURL = bundle.url(forResource: "Smart4SURE", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("Dashboard.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "Smart4SUREScheduledActivityManagerDomain", code: 1, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    lazy var backgroundObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                assertionFailure("Unresolved error \(nserror), \(nserror.userInfo)")
                managedObjectContext.rollback()
            }
        }
    }
    
}
