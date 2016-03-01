//
//  Snapshot.swift
//  Suitcase
//
//  Copyright (c) 2015-2016, Sebastian Staudt
//

import XCTest

class SnapshotSequence: XCTestCase {

    var app = XCUIApplication()

    let exists = NSPredicate(format: "exists == true")

    func launchApp(forSteamId64 steamId64: UInt64) {
        app.launchArguments += ["-SteamID64", String(steamId64)]
        app.launch()

        sleep(5)
    }

    override func setUp() {
        continueAfterFailure = false

        Snapshot.setupSnapshot(app)

        if (isTablet()) {
            XCUIDevice().orientation = UIDeviceOrientation.LandscapeLeft
        }
    }

    func isTablet() -> Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == .Pad
    }

    func selectGame(gameName: String) {
        let gameCell = app.staticTexts[gameName]
        let exists = NSPredicate(format: "exists == true")
        expectationForPredicate(exists, evaluatedWithObject: gameCell, handler: nil)
        waitForExpectationsWithTimeout(60, handler: nil)
        gameCell.tap()
    }

    func testCSGO() {
        launchApp(forSteamId64: 76561197961384956)

        selectGame("Counter-Strike: Global Offensive")

        let name = deviceLanguage == "ru" ? "Расплата" : "Payback"
        app.cells.elementMatchingPredicate(NSPredicate(format: "label CONTAINS %@", name)).tap()

        snapshot("csgo", waitForLoadingIndicator: false)
    }

    func testDota2() {
        launchApp(forSteamId64: 76561197968567369)

        selectGame("Dota 2")

        let firstCell = app.cells.elementBoundByIndex(0)
        let start = firstCell.coordinateWithNormalizedOffset(CGVectorMake(0, 0))
        let finish = firstCell.coordinateWithNormalizedOffset(CGVectorMake(0, 1))
        start.pressForDuration(0, thenDragToCoordinate: finish)

        app.searchFields.element.tap()
        app.searchFields.element.typeText("cor")

        if (isTablet()) {
            app.cells.elementMatchingPredicate(NSPredicate(format: "label CONTAINS %@", "Encore")).tap()
        } else {
            firstCell.swipeUp()
            firstCell.swipeDown()
        }

        snapshot("dota2", waitForLoadingIndicator: false)
    }

    func testGames() {
        launchApp(forSteamId64: 76561197961384956)

        snapshot("games", waitForLoadingIndicator: false)
    }

    func testSettings() {
        launchApp(forSteamId64: 76561197961384956)

        app.navigationBars.buttons["Settings"].tap()

        snapshot("settings", waitForLoadingIndicator: false)
    }

    func testTF2() {
        app.launchArguments += ["-SteamID64", "76561197961384956"]
        app.launch()

        selectGame("Team Fortress 2")

        if (deviceLanguage == "ru") {
            app.cells["Огнемет"].tap()
        } else {
            app.cells.elementBoundByIndex(0).tap()
        }

        snapshot("tf2", waitForLoadingIndicator: false)
    }

}
