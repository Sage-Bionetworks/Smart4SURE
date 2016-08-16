//
//  Smart4SUREUITests.swift
//  Smart4SUREUITests
//
//  Created by Shannon Young on 3/22/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import XCTest

class Smart4SUREUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        app.launchArguments = ["--testId:1230", "--dataGroups:training_user"]
        app.launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAutomaticLogin() {
        let app = XCUIApplication()
        app.tabBars.buttons["Settings"].tap()
        let expectedExternalIdText = app.staticTexts["1230"]
        XCTAssertNotNil(expectedExternalIdText)
    }
    
    // TODO: syoung 07/19/2016 Data refresh doesn't work with UI Testing and KIF breaks with every change of the
    // OS. Instead, adding only this one test to set the externalId to a test account with "training_user"
    // as the only data group. This will facilitate manual testing with a known account. For now, that's the best
    // that I can find that will work consistently. Work-arounds are all brittle and do not work consistently.
}
