// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

class ClipBoardTests: BaseTestCase {
    let url = "www.example.com"

    //Check for test url in the browser
    func checkUrl() {
        let urlTextField = app.textFields["url"]
        waitForValueContains(urlTextField, value: "www.example")
    }

    //Copy url from the browser
    func copyUrl() {
        navigator.goto(URLBarOpen)
        waitForExistence(app.textFields["address"])
        app.textFields["address"].tap()
        waitForExistence(app.menuItems["Copy"])
        app.menuItems["Copy"].tap()
        app.typeText("\r")
        navigator.nowAt(BrowserTab)
    }

    //Check copied url is same as in browser
    func checkCopiedUrl() {
        if let myString = UIPasteboard.general.string {
            var value = app.textFields["url"].value as! String
            if value.hasPrefix("http") == false {
                value = "http://\(value)"
            }
            XCTAssertNotNil(myString)
            XCTAssertEqual(myString, value, "Url matches with the UIPasteboard")
        }
    }

    // This test is disabled in release, but can still run on master
    func testClipboard() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.openURL(url)
        waitUntilPageLoad()
        checkUrl()
        copyUrl()
        checkCopiedUrl()

        navigator.createNewTab()
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(URLBarOpen)
        app.textFields["address"].press(forDuration: 3)
        app.menuItems["Paste"].tap()
        waitForValueContains(app.textFields["address"], value: "www.example.com")
    }

    // Smoketest
    func testClipboardPasteAndGo() {
        navigator.openURL(url)
        waitUntilPageLoad()
        waitForNoExistence(app.staticTexts["Fennec pasted from XCUITests-Runner"])
        navigator.goto(BrowserTabMenu)
        navigator.performAction(Action.CopyAddressPAM)

        checkCopiedUrl()
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        navigator.createNewTab()
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        app.textFields["url"].press(forDuration: 3)
        waitForExistence(app.tables["Context Menu"])
        app.otherElements[ImageIdentifiers.pasteAndGo].tap()
        waitForExistence(app.textFields["url"])
        waitForValueContains(app.textFields["url"], value: "www.example.com")
    }
}
