//
//  Smart4SURELearnInfo.swift
//  BridgeAppSDK
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

protocol Smart4SURELearnItem: class {

    /**
     * Check validity as a Smart4SURELearnItem
     */
    func isValidSmart4SURELearnItem() -> Bool
    
    /**
     * Title to show in the Learn tab table view cell
     */
    var title: String! { get }
    
    /**
     * Content file (html) to load for the Detail view for this item
     */
    var details: String! { get }
    
    /**
     * Name of the image to use as the item's icon in the Learn tab table view cell
     */
    var iconImage: String! { get }
}

extension NSDictionary : Smart4SURELearnItem {
    func isValidSmart4SURELearnItem() -> Bool {
        guard let _ = self["title"] as? String,
              let _ = self["details"] as? String,
              let _ = self["iconImage"] as? String
        else {
            return false
        }
        return true
    }
    
    var title : String! { return self["title"] as! String }
    var details : String! { return self["details"] as! String }
    var iconImage : String! { return self["iconImage"] as! String }
}

protocol Smart4SURELearnInfo: class {
    /**
     * Access the Smart4SURELearnItems to show in the Learn tab table view
     */
    subscript(index: Int) -> Smart4SURELearnItem? { get }
    
    /**
     * See how many Smart4SURELearnItems to show
     */
    var count: Int! { get }
    
}

class Smart4SURELearnInfoPList : NSObject, Smart4SURELearnInfo {
    
    fileprivate var rowItems: [Smart4SURELearnItem]!
    
    convenience override init() {
        self.init(name: "LearnInfo")!
    }
    
    init?(name: String) {
        super.init()
        guard let plist = SBAResourceFinder.shared.plist(forResource: name) else {
            assertionFailure("\(name) plist file not found in the resource bundle")
            return nil
        }
        guard let rowItemsDicts = plist["rowItems"] as? [NSDictionary] else {
            assertionFailure("\(name) plist file does not define 'rowItems' (or it does not contain NSDictionary objects)")
            return nil
        }
        self.rowItems = rowItemsDicts.map({ $0 as Smart4SURELearnItem }).filter({ $0.isValidSmart4SURELearnItem() })
    }
    
    subscript(index: Int) -> Smart4SURELearnItem? {
        guard index >= 0 && index < rowItems.count else {
            assertionFailure("index \(index) out of bounds (0...\(rowItems.count))")
            return nil
        }
        return rowItems[index]
    }
    
    var count : Int! {
        return rowItems.count
    }
}

