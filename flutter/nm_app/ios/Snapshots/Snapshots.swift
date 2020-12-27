// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest

class Snapshots: XCTestCase {

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure
        // occurs.
        continueAfterFailure = false

        // TODO: setup orientation (portrait vs landscape)
    }

    override func tearDownWithError() throws { }

    func testLaunch() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // TODO: Use recording write more "UI tests" for screenshots.
        XCUIApplication().windows.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.tap()
        snapshot("0Launch")

        // TODO: Find a way to insert test. Recording it doesn't seem to work.
    }
}
