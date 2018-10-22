import XCTest

extension SPARQLTests {
    static let __allTests = [
        ("testExample", testExample),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SPARQLTests.__allTests),
    ]
}
#endif
