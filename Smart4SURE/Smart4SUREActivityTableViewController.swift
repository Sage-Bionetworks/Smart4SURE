//
//  Smart4SUREActivityTableViewController.swift
//  Smart4SURE
//
//  Created by Shannon Young on 4/27/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import BridgeSDK
import BridgeAppSDK

class Smart4SUREActivityTableViewController: SBAActivityTableViewController {
    
    override var scheduledActivityManager : SBAScheduledActivityManager  {
        return _scheduledActivityManager
    }
    private let _scheduledActivityManager : SBAScheduledActivityManager = Smart4SUREScheduledActivityManager()
}

class Smart4SUREScheduledActivityManager: SBAScheduledActivityManager {
    
    let kTrainingTaskIdentifier = "1-Training-295f81EF-13CB-4DB4-8223-10A173AA0780"
    let kMedTaskIdentifier = "1-MedicationTracker-20EF8ED2-E461-4C20-9024-F43FCAAAF4C3"
    let kStudyDrugTrackingTaskIdentifier = "1-StudyTracker-408C5ED4-AB61-41d3-AF37-7f44C6A16BBF"
    let kStudyDrugTrackingStepIdentifier = "studyDrugTiming"
    
    let medicationSchemaIdentifier = "Medication Tracker"
    let tappingSchemaIdentifier = "Tapping Activity"
    let voiceSchemaIdentifier = "Voice Activity"
    let memorySchemaIdentifier = "Memory Activity"
    let walkingSchemaIdentifier = "Walking Activity"
    
    func taskViewControllerShouldConfirmCancel(taskViewController: ORKTaskViewController) -> Bool {
        // syoung 05/23/2016 Always override the default action and do not confirm cancellation of
        // a task. The confirmation UI is confusing to participants who are unfamiliar with Apple
        // conventions. Since this is an app designed for use on a phone specific to a short-term
        // clinical trial, we cannot assume that the user is a typical iPhone user.
        return false
    }
    
    // MARK: overrides
    
    override func shouldRecordResult(schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) -> Bool {
        if isStudyDrugTrackingTask(schedule),
            let stepResult = taskViewController.result.stepResultForStepIdentifier(kStudyDrugTrackingStepIdentifier),
            let choiceResult = stepResult.results?.first as? ORKChoiceQuestionResult,
            let answer = choiceResult.choiceAnswers?.first as? Bool {
            // If this is the Study Drug Tracking question, then return the answer to the question
            return answer
        }
        else {
            return super.shouldRecordResult(schedule, taskViewController: taskViewController)
        }
    }
    
    override func loadActivities(scheduledActivities: [SBBScheduledActivity]) {
        // Filter the schedules before passing to super
        let schedules = filterSchedules(scheduledActivities)
        super.loadActivities(schedules)
    }
    
    override func setupNotificationsForScheduledActivities(scheduledActivities: [SBBScheduledActivity]) {
        // Exit early if showing training and none completed otherwise call through to super
        guard sections == [.today] || hasCompletedTrainingToday(scheduledActivities) else { return }
        super.setupNotificationsForScheduledActivities(scheduledActivities)
    }
    
    // MARK: custom handling
    
    func isStudyDrugTrackingTask(schedule: SBBScheduledActivity) -> Bool {
        return (schedule.activity.task != nil) && (schedule.activity.task.identifier == kStudyDrugTrackingTaskIdentifier)
    }
    
    func createScheduleFilters() -> (taskIdFilter: NSPredicate, trainingFilter: NSPredicate) {
        // Check if there are any training tasks scheduled for today
        let taskIdFilter = NSPredicate(format:"taskIdentifier = %@ OR taskIdentifier = %@", kTrainingTaskIdentifier, kMedTaskIdentifier)
        let trainingFilter = NSCompoundPredicate(andPredicateWithSubpredicates: [taskIdFilter, SBBScheduledActivity.availableTodayPredicate()])
        return (taskIdFilter, trainingFilter)
    }
    
    func filterSchedules(scheduledActivities: [SBBScheduledActivity]) -> [SBBScheduledActivity] {
        
        // Check if there are any training tasks scheduled for today
        let (taskIdFilter, trainingFilter) = createScheduleFilters()
        
        // Allow second training session to remain incomplete
        if scheduledActivities.filter({ trainingFilter.evaluateWithObject($0) }).count > 1 {
            
            // The only one time only activities are the medication tracking and training activities
            // If these are valid, then the sections should be one-time and tomorrow
            self.sections = [.today, .tomorrow]
            
            // Filter out non-training and med activities for today
            let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
            let midnightTomorrow = calendar.startOfDayForDate(NSDate(timeIntervalSinceNow: 24*60*60))
            let tomorrowFilter = NSPredicate(format: "scheduledOn >= %@", midnightTomorrow)
            let notTrainingFilter = NSCompoundPredicate(notPredicateWithSubpredicate: taskIdFilter)
            let notTrainingTomorrowFilter = NSCompoundPredicate(andPredicateWithSubpredicates: [tomorrowFilter, notTrainingFilter])
            
            let filter = NSCompoundPredicate(orPredicateWithSubpredicates: [trainingFilter, notTrainingTomorrowFilter])
            let schedules = scheduledActivities.filter({ filter.evaluateWithObject($0) })
            return schedules
            
        }
        else {
            // Otherwise, only show the schedule for today
            self.sections = [.today]
            
            // Filter out training and past activities
            let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
            let midnightToday = calendar.startOfDayForDate(NSDate())
            let midnightTomorrow = calendar.startOfDayForDate(NSDate(timeIntervalSinceNow: 24*60*60))
            let pastFilter = NSPredicate(format: "scheduledOn < %@", midnightToday)
            let tomorrowFilter = NSPredicate(format: "scheduledOn > %@", midnightTomorrow)
            
            // Filter out second instance of schedules if showing two schedules with the same label
            var titles: [String] = []
            let schedules = scheduledActivities.filter({ (schedule) -> Bool in
                
                // Filter out activities scheduled in the past
                if pastFilter.evaluateWithObject(schedule) { return false }
                
                // Always include activities scheduled in the future
                if tomorrowFilter.evaluateWithObject(schedule) { return true }
                
                // Otherwise, look at whether or not the schedule is completed and remove the duplicate
                // Assumption: cached activities (completed and expired) are inserted at the beginning of the array
                if (schedule.isCompleted) {
                    // If completed, then add to the list of titles for the completed task and return true
                    // this schedule should be included b/c it was completed
                    titles += [schedule.activity.label]
                    return true
                }
                else {
                    // If the activity is scheduled for today AND there is already a completed activity
                    // in the list then do not include it in the returned array
                    return !titles.contains(schedule.activity.label)
                }
            })
            return schedules
        }
    }
    
    func hasCompletedTrainingToday(scheduledActivities: [SBBScheduledActivity]) -> Bool {
        let (_, trainingFilter) = createScheduleFilters()
        let completedFilter = SBBScheduledActivity.finishedTodayPredicate()
        let completedTrainingFilter = NSCompoundPredicate(andPredicateWithSubpredicates: [trainingFilter, completedFilter])
        return scheduledActivities.filter({ completedTrainingFilter.evaluateWithObject($0) }).count >= 1
    }
    
    // Archive validation
    
    override func jsonValidationMapping(activityResult activityResult: SBAActivityResult) -> [String : NSPredicate]? {
        
        // Include some basic schema validation to check for presence of required json results
        
        switch activityResult.schemaIdentifier {
            
        case medicationSchemaIdentifier:
            return [
                "medicationSelection.json"  : NSPredicate(format: "items <> NULL"),
                "affectedHand.json"         : NSPredicate(format: "choiceAnswers <> NULL"),
                "dominantHand.json"         : NSPredicate(format: "choiceAnswers <> NULL"),
            ];
            
        case tappingSchemaIdentifier,
             voiceSchemaIdentifier,
             walkingSchemaIdentifier:
            return [
                "medicationActivityTiming.json"     : NSPredicate(format: "choiceAnswers <> NULL"),
            ];
            
        case memorySchemaIdentifier:
            return [
                "medicationActivityTiming.json"     : NSPredicate(format: "choiceAnswers <> NULL"),
                "cognitive_memory_spatialspan.json" : NSPredicate(format: "MemoryGameOverallScore <> NULL AND MemoryGameNumberOfGames <> NULL AND MemoryGameNumberOfFailures <> NULL AND MemoryGameGameRecords <> NULL"),
            ];
            
        default:
            return nil
        }
    }
    
}
