import XCTest

extension SPARQLTests {
    static let __allTests = [
        ("testBasic", testBasic),
        ("testComplex", testComplex),
        ("testGroup", testGroup),
        ("testNestedDirectProject", testNestedDirectProject),
        ("testNestedDistinct", testNestedDistinct),
        ("testNestedProject", testNestedProject),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SPARQLTests.__allTests),
    ]
}
#endif
