//
//  Smart4SUREActivityTableViewController.swift
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

import BridgeSDK
import BridgeAppSDK

class S4S: NSObject {
    
    static let kActivitySessionTaskId = "1-Combined"
    static let kTrainingSessionTaskId = "1-Training-Combined"
    
    static let kComboPredicate = NSPredicate(format:"finishedOn = NULL AND taskIdentifier = %@", kActivitySessionTaskId)
}

class Smart4SUREActivityTableViewController: SBAActivityTableViewController {
    
    override var scheduledActivityManager : SBAScheduledActivityManager  {
        return _scheduledActivityManager
    }
    private let _scheduledActivityManager : SBAScheduledActivityManager = Smart4SUREScheduledActivityManager()
}

class Smart4SUREScheduledActivityManager: SBAScheduledActivityManager {
    
    override init() {
        super.init()
        self.daysAhead = 10
        self.sections = [.expiredYesterday, .today, .keepGoing, .comingWeek]
    }
    
    override func loadActivities(scheduledActivities: [SBBScheduledActivity]) {
        // Filter the schedules before passing to super
        let schedules = filterSchedules(scheduledActivities)
        super.loadActivities(schedules)
    }
    
    func filterSchedules(scheduledActivities: [SBBScheduledActivity]) -> [SBBScheduledActivity] {
        
        let schedules = scheduledActivities.map { (schedule) -> [SBBScheduledActivity] in
            
            // If this is not a combo schedule then return the schedule
            guard S4S.kComboPredicate.evaluateWithObject(schedule) else { return [schedule] }
            
            // Split the schedule into three days
            let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
            var scheduleMidnightDate = calendar.startOfDayForDate(schedule.scheduledOn)
            let scheduledOnComponents = calendar.components([.Hour, .Minute], fromDate: schedule.scheduledOn)
            let expiredOnComponents = calendar.components([.Hour, .Minute], fromDate: schedule.expiresOn)
            
            var activities: [SBBScheduledActivity] = []
            for _ in 0 ..< 3 {
                
                // Pull the date for 3 days in a row and union with the time for start/end
                // Need to check the year/month/day because these can cross calendar boundaries
                let dateComponents = calendar.components([.Year, .Month, .Day], fromDate: scheduleMidnightDate)
                
                scheduledOnComponents.year = dateComponents.year
                scheduledOnComponents.month = dateComponents.month
                scheduledOnComponents.day = dateComponents.day
                
                expiredOnComponents.year = dateComponents.year
                expiredOnComponents.month = dateComponents.month
                expiredOnComponents.day = dateComponents.day
                
                let activity = schedule.copy() as! SBBScheduledActivity
                activity.scheduledOn = calendar.dateFromComponents(scheduledOnComponents)
                activity.expiresOn = calendar.dateFromComponents(expiredOnComponents)
                activities.append(activity)
                
                scheduleMidnightDate = scheduleMidnightDate.dateByAddingTimeInterval(24 * 60 * 60)
            }
            
            return activities
            
        }.flatMap({ $0 })

        return schedules
    }
    
}
