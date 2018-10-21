import XCTest

import SPARQLTests

var tests = [XCTestCaseEntry]()
tests += SPARQLTests.allTests()
XCTMain(tests)