//
//  Smart4SURETests.swift
//  Smart4SURETests
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

import XCTest
@testable import Smart4SURE

import BridgeAppSDK
import BridgeSDK

class Smart4SURETests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDivideComboSessionByThree() {
        
        let registeredOn = NSDate().dateAtMilitaryTime(7)
        let trainingFinishedOn = NSDate().dateAtMilitaryTime(11)
        
        let pdq8 = createScheduledSurvey("PDQ8", label: "PDQ-8 Questionnaire")
        let trainingTask = createTrainingSession(registeredOn, finishedOn: trainingFinishedOn)
        let activities = createActivitySessions(trainingFinishedOn)
        let initialSchedules = [trainingTask, pdq8] + activities
        
        let manager = Smart4SUREScheduledActivityManager()
        
        // -- method under test
        let schedules = manager.filterSchedules(initialSchedules)
        
        // Check that the activity schedules are split across 3 days
        let activitySchedules = schedules.filter({ $0.taskIdentifier == "1-Combined"})
        XCTAssertEqual(activitySchedules.count, 6)
        
        guard activitySchedules.count == 6 else { return }
        
        checkTimeSplit(Array(activitySchedules[0..<3]))
        checkTimeSplit(Array(activitySchedules[3..<6]))
    }
    
    func testDivideComboSessionByThree_WithCompleted() {
        
        let trainingFinishedOn = NSDate().dateAtMilitaryTime(11).dateByAddingTimeInterval(-8 * 24 * 60 * 60)
        
        let pdq8 = createScheduledSurvey("PDQ8", label: "PDQ-8 Questionnaire")
        let activities = createActivitySessions(trainingFinishedOn)
        let initialSchedules = [pdq8] + activities
        
        // Mark the activity as finished
        activities[0].finishedOn = NSDate().dateAtMilitaryTime(10.5)
        
        let manager = Smart4SUREScheduledActivityManager()
        
        // -- method under test
        let schedules = manager.filterSchedules(initialSchedules)
        
        // Check that the activity schedules are split across 3 days
        // But only for the activity that has *not* been completed
        let activitySchedules = schedules.filter({ $0.taskIdentifier == "1-Combined"})
        XCTAssertEqual(activitySchedules.count, 4)
        
        guard activitySchedules.count == 4 else { return }
        
        checkTimeSplit(Array(activitySchedules[1..<4]))
    }
    
    func checkTimeSplit(schedules:[SBBScheduledActivity]) {
        guard schedules.count == 3 else { return }
        
        let scheduleDay1 = schedules[0]
        let scheduleDay2 = schedules[1]
        let scheduleDay3 = schedules[2]
        
        let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
        
        let expectedTime = "10:00 am"
        XCTAssertEqual(scheduleDay1.scheduledTime, expectedTime)
        XCTAssertEqual(scheduleDay2.scheduledTime, expectedTime)
        XCTAssertEqual(scheduleDay3.scheduledTime, expectedTime)
        
        let expiredTime1 = calendar.component(.Hour, fromDate: scheduleDay1.expiresOn)
        let expiredTime2 = calendar.component(.Hour, fromDate: scheduleDay2.expiresOn)
        let expiredTime3 = calendar.component(.Hour, fromDate: scheduleDay3.expiresOn)
        let expectedExpired = 12
        XCTAssertEqual(expiredTime1, expectedExpired)
        XCTAssertEqual(expiredTime2, expectedExpired)
        XCTAssertEqual(expiredTime3, expectedExpired)
        
        let day1 = calendar.component(.Day, fromDate: scheduleDay1.scheduledOn)
        let day2 = calendar.component(.Day, fromDate: scheduleDay2.scheduledOn)
        let day3 = calendar.component(.Day, fromDate: scheduleDay3.scheduledOn)
        XCTAssertEqual(day2, day1 + 1)
        XCTAssertEqual(day3, day1 + 2)
    }
    
    // MARK: helper methods
    
    func createTrainingSession(registeredOn: NSDate, finishedOn: NSDate?) -> SBBScheduledActivity {
        return createScheduledActivity("1-Training-Combined", label: "Training Session",
                scheduledOn: registeredOn, finishedOn: finishedOn, expiresOn: nil)
    }
    
    func createActivitySessions(trainingFinishedOn: NSDate = NSDate()) -> [SBBScheduledActivity] {
        
        var schedules: [SBBScheduledActivity] = []
        
        let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
        let hour: NSTimeInterval = 60 * 60
        let day: NSTimeInterval = 24 * hour
        let week: NSTimeInterval = 7 * day
        var midnight = calendar.startOfDayForDate(trainingFinishedOn.dateByAddingTimeInterval(week))
        
        for _ in 1...2 {

            let scheduledOn = midnight.dateByAddingTimeInterval(10 * hour)
            let expiredOn = scheduledOn.dateByAddingTimeInterval(2*day + 2*hour)
            let schedule = createScheduledActivity("1-Combined", label: "Activity Session", scheduledOn: scheduledOn, finishedOn: nil, expiresOn: expiredOn)
            schedules.append(schedule)
            
            // Advance midnight by 1 week
            midnight = midnight.dateByAddingTimeInterval(week)
        }
        
        return schedules
    }
    
    func createScheduledActivity(taskId: String, label: String, scheduledOn:NSDate = NSDate(), finishedOn:NSDate? = nil, expiresOn:NSDate? = nil) -> SBBScheduledActivity {
        
        let schedule = SBBScheduledActivity()
        schedule.guid = NSUUID().UUIDString
        schedule.activity = SBBActivity()
        schedule.activity.label = label
        schedule.activity.guid = NSUUID().UUIDString
        schedule.activity.task = SBBTaskReference()
        schedule.activity.task.identifier = taskId
        schedule.scheduledOn = scheduledOn
        schedule.expiresOn = expiresOn
        schedule.finishedOn = finishedOn
        return schedule
    }
    
    func createScheduledSurvey(taskId: String, label: String, scheduledOn:NSDate = NSDate(), finishedOn:NSDate? = nil, expiresOn:NSDate? = nil) -> SBBScheduledActivity {
        
        let schedule = SBBScheduledActivity()
        schedule.guid = NSUUID().UUIDString
        schedule.activity = SBBActivity()
        schedule.activity.label = label
        schedule.activity.guid = NSUUID().UUIDString
        schedule.activity.survey = SBBSurveyReference()
        schedule.activity.survey.guid = NSUUID().UUIDString
        schedule.activity.survey.href = schedule.activity.survey.guid
        schedule.activity.survey.identifier = taskId
        schedule.scheduledOn = scheduledOn
        schedule.expiresOn = expiresOn
        schedule.finishedOn = finishedOn
        return schedule
    }
    
}

extension NSDate {
    
    func dateAtMilitaryTime(time: NSTimeInterval) -> NSDate {
        let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
        let hour: NSTimeInterval = 60 * 60
        return calendar.startOfDayForDate(self).dateByAddingTimeInterval(time * hour)
    }
    
}

extension Array {
    
    func elementAtIndex(index: Int) -> Element? {
        guard index < self.count else { return nil }
        return self[index]
    }
}
