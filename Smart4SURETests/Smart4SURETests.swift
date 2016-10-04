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
    
    func testResources_Onboarding() {
        let onboardingVC = Smart4SUREOnboardingViewController()
        XCTAssertNotNil(onboardingVC)
    }
    
    func testResources_CombineTask_Training() {
        let trainingTask = createTrainingSession(Date(), finishedOn: nil)
        let manager = Smart4SUREScheduledActivityManager()
        let (task, taskRef) = manager.createTask(for: trainingTask)
        XCTAssertNotNil(task)
        XCTAssertNotNil(taskRef)
    }
    
    func testResources_CombineTask_Ongoing() {
        let schedules = createActivitySessions(Date().addingNumberOfDays(-10))
        let manager = Smart4SUREScheduledActivityManager()
        let (task, taskRef) = manager.createTask(for: schedules[0])
        XCTAssertNotNil(task)
        XCTAssertNotNil(taskRef)
    }
    
    func testHasAllBaseline_TrainingToday() {
        
        let registeredOn = Date().addingNumberOfDays(-10).dateAtMilitaryTime(9)
        let trainingFinishedOn = Date().dateAtMilitaryTime(11)
        
        let pdq8 = createScheduledSurvey("PDQ8", label: "PDQ-8 Questionnaire")
        let trainingTask = createTrainingSession(registeredOn, finishedOn: trainingFinishedOn)
        let baseline = createBaselineSessions(trainingFinishedOn)
        let activities = createActivitySessions(trainingFinishedOn)
        let initialSchedules = [trainingTask, pdq8] + activities + baseline
        
        let manager = Smart4SUREScheduledActivityManager()
        
        // -- method under test
        let schedules = manager.filterSchedules(initialSchedules)
        
        // If training was today then baseline should be scheduled for tomorrow
        checkTimeSplit(schedules, expectedDate: Date().addingNumberOfDays(1))
    }
    
    func testHasAllBaseline_TrainingLastWeek() {
        
        let registeredOn = Date().addingNumberOfDays(-10).dateAtMilitaryTime(9)
        let trainingFinishedOn = Date().addingNumberOfDays(-7).dateAtMilitaryTime(11)
        
        let pdq8 = createScheduledSurvey("PDQ8", label: "PDQ-8 Questionnaire")
        let trainingTask = createTrainingSession(registeredOn, finishedOn: trainingFinishedOn)
        let baseline = createBaselineSessions(trainingFinishedOn)
        let activities = createActivitySessions(trainingFinishedOn)
        let initialSchedules = [trainingTask, pdq8] + activities + baseline
        
        let manager = Smart4SUREScheduledActivityManager()
        
        // -- method under test
        let schedules = manager.filterSchedules(initialSchedules)
        
        // If training was last week then baseline should be scheduled for today
        checkTimeSplit(schedules, expectedDate: Date())
    }
    
    // MARK: helper methods
    
    func checkTimeSplit(_ schedules:[SBBScheduledActivity], expectedDate: Date) {
        
        // Check that the ongoing scheduled tasks are filtered out
        let ongoingSchedules = schedules.filter({ $0.taskIdentifier == "Ongoing-Combined"})
        XCTAssertEqual(ongoingSchedules.count, 0)
        
        let baselineSchedules = schedules.filter({ $0.taskIdentifier == "Baseline-Combined"})
        XCTAssertEqual(baselineSchedules.count, 3)
        
        guard baselineSchedules.count == 3 else { return }
        
        let scheduleDay1 = baselineSchedules[0]
        let scheduleDay2 = baselineSchedules[1]
        let scheduleDay3 = baselineSchedules[2]
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        
        // scheduled time is expected
        let scheduleTime1 = (calendar as NSCalendar).component(.hour, from: scheduleDay1.scheduledOn)
        let scheduleTime2 = (calendar as NSCalendar).component(.hour, from: scheduleDay2.scheduledOn)
        let scheduleTime3 = (calendar as NSCalendar).component(.hour, from: scheduleDay3.scheduledOn)
        XCTAssertEqual(scheduleTime1, 6)
        XCTAssertEqual(scheduleTime2, 12)
        XCTAssertEqual(scheduleTime3, 18)
        
        // Expired time is expected
        let expiredTime1 = (calendar as NSCalendar).component(.hour, from: scheduleDay1.expiresOn)
        let expiredTime2 = (calendar as NSCalendar).component(.hour, from: scheduleDay2.expiresOn)
        let expiredTime3 = (calendar as NSCalendar).component(.hour, from: scheduleDay3.expiresOn)
        XCTAssertEqual(expiredTime1, 12)
        XCTAssertEqual(expiredTime2, 18)
        XCTAssertEqual(expiredTime3, 0)
        
        // Scheduled date is expected
        for schedule in baselineSchedules {
            XCTAssertFalse(schedule.isExpired)
            let expiresHours = calendar.dateComponents([.hour], from: schedule.scheduledOn, to: schedule.expiresOn)
            XCTAssertEqual(expiresHours.hour!, 6)
        }
    }
    
    func createTrainingSession(_ registeredOn: Date, finishedOn: Date?) -> SBBScheduledActivity {
        return createScheduledActivity("Training-Combined", label: "Training Session",
                scheduledOn: registeredOn, finishedOn: finishedOn, expiresOn: nil)
    }
    
    func createActivitySessions(_ trainingFinishedOn: Date) -> [SBBScheduledActivity] {
        
        var schedules: [SBBScheduledActivity] = []
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let hour: TimeInterval = 60 * 60
        var midnight = calendar.startOfDay(for: trainingFinishedOn.addingNumberOfDays(7))
        
        for _ in 1...2 {

            let scheduledOn = midnight.addingTimeInterval(12 * hour)
            let expiredOn = scheduledOn.addingNumberOfDays(7)
            let schedule = createScheduledActivity("Ongoing-Combined", label: "Activity Session", scheduledOn: scheduledOn, finishedOn: nil, expiresOn: expiredOn)
            schedules.append(schedule)
            
            // Advance midnight by 1 week
            midnight = midnight.addingNumberOfDays(7)
        }
        
        return schedules
    }
    
    func createBaselineSessions(_ trainingFinishedOn: Date) -> [SBBScheduledActivity] {
        
        var schedules: [SBBScheduledActivity] = []
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let hour: TimeInterval = 60 * 60
        let midnight = calendar.startOfDay(for: trainingFinishedOn.addingNumberOfDays(1))
        var scheduledOn = midnight.addingTimeInterval(6 * hour)
        
        for _ in 1...3 {
            
            let expiredOn = scheduledOn.addingNumberOfDays(45)
            let schedule = createScheduledActivity("Baseline-Combined", label: "Activity Session", scheduledOn: scheduledOn, finishedOn: nil, expiresOn: expiredOn)
            schedules.append(schedule)
            
            // Advance the time
            scheduledOn = scheduledOn.addingTimeInterval(6 * hour)
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
