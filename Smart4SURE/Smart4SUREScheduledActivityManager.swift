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
    
    static let kBaselineSessionTaskId = "Baseline-Combined"
    static let kOngoingSessionTaskId = "Ongoing-Combined"
    static let kTrainingSessionTaskId = "Training-Combined"
    
    static let kBaselinePredicate = NSPredicate(format:"finishedOn = NULL AND taskIdentifier = %@", kBaselineSessionTaskId)
    
    static let kTimeWindow = 6                  // Number of hours before the task expires
    static let kDefaultNotificationTime = 12    // Time of day to set notification
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
        
        // Setup notifications that require custom coding
        setupCustomNotifications(scheduledActivities)
        
        // Filter and edit the schedules before passing to super
        let schedules = filterSchedules(scheduledActivities)
        super.load(scheduledActivities: schedules)
    }
    
    func filterSchedules(_ scheduledActivities: [SBBScheduledActivity]) -> [SBBScheduledActivity] {
        
        // If there is more than 1 baseline schedule, then filter out the activities schedules
        let baselineScheduleFound = (scheduledActivities.filter({ S4S.kBaselinePredicate.evaluate(with: $0) }).count > 1)
        
        let allSchedules = scheduledActivities.mapAndFilter { (schedule) -> SBBScheduledActivity? in
            if baselineScheduleFound && schedule.taskIdentifier == S4S.kOngoingSessionTaskId {
                return nil
            }
            else if S4S.kBaselinePredicate.evaluate(with: schedule) {
                return updatedBaselineSchedule(schedule)
            }
            return schedule
        }
        
        return allSchedules
    }
    
    func updatedBaselineSchedule(_ schedule: SBBScheduledActivity) -> SBBScheduledActivity {
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let scheduleDay = Date().compare(schedule.scheduledOn) == .orderedAscending ? schedule.scheduledOn! : Date()
        
        // Create a copy with modified the scheduled time and detail
        let activity = schedule.copy() as! SBBScheduledActivity
        activity.scheduledOn = merge(day: scheduleDay, time: schedule.scheduledOn)
        activity.expiresOn = calendar.date(byAdding: .hour, value: S4S.kTimeWindow, to: activity.scheduledOn)
        
        // Check that the activity is not expired and if so, forward the time
        if activity.isExpired {
            activity.scheduledOn = activity.scheduledOn.addingNumberOfDays(1)
            activity.expiresOn = activity.expiresOn.addingNumberOfDays(1)
        }

        return activity
    }
    
    
    // MARK: Custom Notification handling
    
    func setupCustomNotifications(_ scheduledActivities: [SBBScheduledActivity]) {
        
        // Setup a notification for each reminder in the set
        // Start by cancelling the existing reminder
        UIApplication.shared.cancelAllLocalNotifications()
        
        // Add reminders for both baseline and noon time
        addRemindersForBaseline(scheduledActivities)
        addNoonTimeReminders(scheduledActivities)
    }
    
    func addRemindersForBaseline(_ scheduledActivities: [SBBScheduledActivity]) {

        // For the baseline session, only add the reminders if not completed,
        // and add then add them based on the scheduled time, offset by 2 hours and
        // with a reminder scheduled every 3 days until expired
        
        for schedule in scheduledActivities {
            if !schedule.isCompleted && schedule.taskIdentifier == S4S.kBaselineSessionTaskId {
        
                // Offset by 2 hours
                var reminder = schedule.scheduledOn.addingTimeInterval(2 * 60 * 60)
                
                // Add dates for the baseline session
                repeat {
                    let alertText = Localization.localizedStringWithFormatKey("SBA_TIME_FOR_%@", schedule.activity.label)
                    addNotification(reminder: reminder, alertText: alertText)
                    reminder = reminder.addingNumberOfDays(3)
                } while (reminder < schedule.expiresOn)
            }
        }
    }
    
    func addNoonTimeReminders(_ scheduledActivities: [SBBScheduledActivity]) {
        
        var reminders = Set<Date>()
        var activityGuids = Array<String>()
        
        let schedules = scheduledActivities.filter({ $0.scheduledOn != nil })
            .sorted(by: { $0.0.scheduledOn.compare($0.1.scheduledOn) == .orderedAscending })
        
        for schedule in schedules {
            if !activityGuids.contains(schedule.activity.guid) {
                activityGuids.append(schedule.activity.guid)
                
                if let taskIdentifier = schedule.taskIdentifier,
                    taskIdentifier == S4S.kOngoingSessionTaskId {
                    reminders.formUnion(remindersForOngoing(schedule: schedule))
                }
                else if schedule.surveyIdentifier != nil {
                    reminders.formUnion(remindersForSurvey(schedule: schedule))
                }
            }
        }
        
        // Add earliest reminders first
        let sortedReminders = reminders.sorted()
        for reminder in sortedReminders {
            addNotification(reminder: reminder.dateAtMilitaryTime(S4S.kDefaultNotificationTime),
                            alertText: NSLocalizedString("Smart4SURE needs your help. Please complete activities and surveys session when it is most convenient for you today.", comment: ""))
        }
    }
    
    func addNotification(reminder: Date, alertText: String) {
        let tomorrow = Date().addingNumberOfDays(1).startOfDay()
        if tomorrow.compare(reminder) == .orderedAscending {
            let notification = UILocalNotification()
            notification.fireDate = reminder
            notification.soundName = UILocalNotificationDefaultSoundName
            notification.alertBody = alertText
            UIApplication.shared.scheduleLocalNotification(notification)
        }
    }
    
    func remindersForOngoing(schedule: SBBScheduledActivity) -> Set<Date> {

        // Look for a schedule matching the last time ANY activity session was completed
        let baselinePredicate = NSPredicate(format: "taskIdentifier = %@", S4S.kBaselineSessionTaskId)
        let ongoingPredicate = NSPredicate(format: "taskIdentifier = %@", S4S.kOngoingSessionTaskId)
        let trainingPredicate = NSPredicate(format: "taskIdentifier = %@", S4S.kTrainingSessionTaskId)
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [baselinePredicate, ongoingPredicate, trainingPredicate])
        
        // Set the reminders for every 30 days
        return remindersForActivityMatching(predicate: predicate, schedule: schedule, increment: 30)
    }
    
    func remindersForSurvey(schedule: SBBScheduledActivity) -> Set<Date> {
        // For the surveys, only want to remind every 90 days
        let predicate = NSPredicate(format: "surveyIdentifier = %@", schedule.surveyIdentifier!)
        return remindersForActivityMatching(predicate: predicate, schedule: schedule, increment: 90)
    }
    
    func remindersForActivityMatching(predicate: NSPredicate, schedule:SBBScheduledActivity, increment: Int) -> Set<Date> {
        
        let lastCompleted = lastCompletedSchedule(predicate: predicate)
        
        var lastDate: Date = {
            if let finishedOn = lastCompleted?.finishedOn {
                return merge(day: finishedOn, time: schedule.scheduledOn)
            }
            else {
                return schedule.scheduledOn
            }
        }()
        
        // Setup dates for the next 360 days
        var reminders = Set<Date>()
        for _ in stride(from: increment, to: 180, by: increment) {
            lastDate = lastDate.addingNumberOfDays(increment)
            for ii in 0..<3 {
                reminders.insert(lastDate.addingNumberOfDays(ii))
            }
        }
        
        return reminders
    }
    
    func lastCompletedSchedule(predicate: NSPredicate) -> SBBScheduledActivity? {
        var lastCompleted: SBBScheduledActivity?
        
        let context = backgroundObjectContext
        context.performAndWait {
            
            let fetchRequest: NSFetchRequest<ScheduledActivity> = ScheduledActivity.fetchResult()
            let finishedPredicate = NSPredicate(format: "finishedOn <> nil")
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [finishedPredicate, predicate])
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "finishedOn", ascending: false)]
            
            do {
                let fetchedSchedules = try context.fetch(fetchRequest)
                lastCompleted = fetchedSchedules.first?.scheduledActivity()
                
            } catch let error as NSError {
                assertionFailure("Error finding schedule: \(error.localizedFailureReason)")
                context.rollback()
            }
        }
        
        return lastCompleted
    }
    
    func merge(day: Date, time: Date) -> Date {
        
        // Split the schedule into three days
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let timeComponents = (calendar as NSCalendar).components([.hour, .minute], from: time)
        
        // Pull the day
        var dateComponents = (calendar as NSCalendar).components([.year, .month, .day], from: day)
        
        // Set the time
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        
        return calendar.date(from: dateComponents)!
    }
    
    
    // MARK: - Update schedule
    
    func updateSchedules(_ scheduledActivities: [SBBScheduledActivity]) {
        
        let schedules = scheduledActivities.sorted(by: { $0.0.guid > $0.1.guid })
        guard schedules.count > 0 else { return }
        
        let context = backgroundObjectContext
        context.perform {
            
            let fetchRequest: NSFetchRequest<ScheduledActivity> = ScheduledActivity.fetchResult()
            fetchRequest.predicate = NSPredicate(format: "guid IN %@", schedules.map({ $0.guid }))
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "guid", ascending: true)]
            fetchRequest.fetchLimit = 1
            
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
                    mo.activityGuid = schedule.activity.guid
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
            let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                            NSInferMappingModelAutomaticallyOption: true]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
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

public extension SBBScheduledActivity {
    
    public dynamic var surveyIdentifier: String? {
        guard self.activity.survey != nil else { return nil }
        return self.activity.survey.identifier
    }
}

public extension Date {
    
    public func dateAtMilitaryTime(_ hour: Int) -> Date {
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: self)!
    }
    
}
