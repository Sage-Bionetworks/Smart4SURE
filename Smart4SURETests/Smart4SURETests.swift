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
        
        let registeredOn = Date().dateAtMilitaryTime(7)
        let trainingFinishedOn = Date().dateAtMilitaryTime(11)
        
        let pdq8 = createScheduledSurvey("PDQ8", label: "PDQ-8 Questionnaire")
        let trainingTask = createTrainingSession(registeredOn, finishedOn: trainingFinishedOn)
        let activities = createActivitySessions(trainingFinishedOn)
        let initialSchedules = [trainingTask, pdq8] + activities
        
        let manager = Smart4SUREScheduledActivityManager()
        
        // -- method under test
        let schedules = manager.filterSchedules(initialSchedules)
        
        // Check that the activity schedules are split across 3 days
        let activitySchedules = schedules.filter({ $0.taskIdentifier == "1-Combined"})
        XCTAssertEqual(activitySchedules.count, 3)
        
        guard activitySchedules.count == 3 else { return }
        
        checkTimeSplit(Array(activitySchedules[0..<3]))
    }
    
    func testDivideComboSessionByThree_WithCompleted() {
        
        let trainingFinishedOn = Date().dateAtMilitaryTime(11).addingTimeInterval(-8 * 24 * 60 * 60)
        
        let pdq8 = createScheduledSurvey("PDQ8", label: "PDQ-8 Questionnaire")
        let activities = createActivitySessions(trainingFinishedOn)
        let initialSchedules = [pdq8] + activities
        
        // Mark the activity as finished
        activities[0].finishedOn = Date().dateAtMilitaryTime(10.5)
        
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
    
    // MARK: helper methods
    
    func checkTimeSplit(_ schedules:[SBBScheduledActivity]) {
        guard schedules.count == 3 else { return }
        
        let scheduleDay1 = schedules[0]
        let scheduleDay2 = schedules[1]
        let scheduleDay3 = schedules[2]
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        
        let expectedTime = "10:00 AM"
        XCTAssertEqual(scheduleDay1.scheduledTime, expectedTime)
        XCTAssertEqual(scheduleDay2.scheduledTime, expectedTime)
        XCTAssertEqual(scheduleDay3.scheduledTime, expectedTime)
        
        let expiredTime1 = (calendar as NSCalendar).component(.hour, from: scheduleDay1.expiresOn)
        let expiredTime2 = (calendar as NSCalendar).component(.hour, from: scheduleDay2.expiresOn)
        let expiredTime3 = (calendar as NSCalendar).component(.hour, from: scheduleDay3.expiresOn)
        let expectedExpired = 12
        XCTAssertEqual(expiredTime1, expectedExpired)
        XCTAssertEqual(expiredTime2, expectedExpired)
        XCTAssertEqual(expiredTime3, expectedExpired)
        
        let dayInterval = TimeInterval(24 * 60 * 60)
        XCTAssertEqual(scheduleDay1.scheduledOn.addingTimeInterval(dayInterval), scheduleDay2.scheduledOn)
        XCTAssertEqual(scheduleDay1.scheduledOn.addingTimeInterval(2 * dayInterval), scheduleDay3.scheduledOn)
        
        for schedule in schedules {
            XCTAssertNotNil(schedule.activity)
            XCTAssertEqual(schedule.taskIdentifier, "1-Combined")
            XCTAssertNil(schedule.finishedOn)
        }
    }
    
    func createTrainingSession(_ registeredOn: Date, finishedOn: Date?) -> SBBScheduledActivity {
        return createScheduledActivity("1-Training-Combined", label: "Training Session",
                scheduledOn: registeredOn, finishedOn: finishedOn, expiresOn: nil)
    }
    
    func createActivitySessions(_ trainingFinishedOn: Date = Date()) -> [SBBScheduledActivity] {
        
        var schedules: [SBBScheduledActivity] = []
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let hour: TimeInterval = 60 * 60
        let day: TimeInterval = 24 * hour
        let week: TimeInterval = 7 * day
        var midnight = calendar.startOfDay(for: trainingFinishedOn.addingTimeInterval(week))
        
        for _ in 1...2 {

            let scheduledOn = midnight.addingTimeInterval(10 * hour)
            let expiredOn = scheduledOn.addingTimeInterval(2*day + 2*hour)
            let schedule = createScheduledActivity("1-Combined", label: "Activity Session", scheduledOn: scheduledOn, finishedOn: nil, expiresOn: expiredOn)
            schedules.append(schedule)
            
            // Advance midnight by 1 week
            midnight = midnight.addingTimeInterval(week)
        }
        
        return schedules
    }
    
    func createScheduledActivity(_ taskId: String, label: String, scheduledOn:Date = Date(), finishedOn:Date? = nil, expiresOn:Date? = nil) -> SBBScheduledActivity {
        
        let schedule = SBBScheduledActivity()
        schedule.guid = UUID().uuidString
        schedule.activity = SBBActivity()
        schedule.activity.label = label
        schedule.activity.guid = UUID().uuidString
        schedule.activity.task = SBBTaskReference()
        schedule.activity.task.identifier = taskId
        schedule.scheduledOn = scheduledOn
        schedule.expiresOn = expiresOn
        schedule.finishedOn = finishedOn
        return schedule
    }
    
    func createScheduledSurvey(_ taskId: String, label: String, scheduledOn:Date = Date(), finishedOn:Date? = nil, expiresOn:Date? = nil) -> SBBScheduledActivity {
        
        let schedule = SBBScheduledActivity()
        schedule.guid = UUID().uuidString
        schedule.activity = SBBActivity()
        schedule.activity.label = label
        schedule.activity.guid = UUID().uuidString
        schedule.activity.survey = SBBSurveyReference()
        schedule.activity.survey.guid = UUID().uuidString
        schedule.activity.survey.href = schedule.activity.survey.guid
        schedule.activity.survey.identifier = taskId
        schedule.scheduledOn = scheduledOn
        schedule.expiresOn = expiresOn
        schedule.finishedOn = finishedOn
        return schedule
    }
    
}

extension Date {
    
    func dateAtMilitaryTime(_ time: TimeInterval) -> Date {
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let hour: TimeInterval = 60 * 60
        return calendar.startOfDay(for: self).addingTimeInterval(time * hour)
    }
    
}

extension Array {
    
    func elementAtIndex(_ index: Int) -> Element? {
        guard index < self.count else { return nil }
        return self[index]
    }
}
