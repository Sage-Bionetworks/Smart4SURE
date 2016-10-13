//
//  ScheduledActivity.swift
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

import Foundation
import BridgeSDK


class ScheduledActivity: NSManagedObject {

    func scheduledActivity() -> SBBScheduledActivity {
        
        let schedule = SBBScheduledActivity()
        
        schedule.guid = self.guid
        schedule.scheduledOn = self.scheduledOn
        schedule.expiresOn = self.expiresOn
        schedule.startedOn = self.startedOn
        schedule.finishedOn = self.finishedOn
        schedule.persistent = self.persistent
        schedule.status = self.status
        
        schedule.activity = SBBActivity()
        schedule.activity.label = self.label
        if let finishedOn = self.finishedOn {
            let format = NSLocalizedString("Completed: %@", comment: "Label for a completed activity")
            let dateString = DateFormatter.localizedString(from: finishedOn, dateStyle: .short, timeStyle: .short)
            schedule.activity.labelDetail = String.localizedStringWithFormat(format, dateString)
        }
        else if let expiresOn = self.expiresOn {
            let format = NSLocalizedString("Expired: %@", comment: "Label for a completed activity")
            let dateString = DateFormatter.localizedString(from: expiresOn, dateStyle: .short, timeStyle: .short)
            schedule.activity.labelDetail = String.localizedStringWithFormat(format, dateString)
        }
        
        return schedule
    }

    class func fetchResult() -> NSFetchRequest<ScheduledActivity> {
        if #available(iOS 10.0, *) {
            return ScheduledActivity.fetchRequest() as! NSFetchRequest<ScheduledActivity>
        } else {
            return NSFetchRequest(entityName: "ScheduledActivity")
        }
    }
    
}
