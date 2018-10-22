import XCTest

import SPARQLTests

var tests = [XCTestCaseEntry]()
tests += SPARQLTests.__allTests()

XCTMain(tests)
