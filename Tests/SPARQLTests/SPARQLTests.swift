import XCTest
@testable import SPARQL
import DiffedAssertEqual

final class SPARQLTests: XCTestCase {

    func testBasic() throws {
        let query =
            Query(op:
                .project(
                    ["a"],
                    .bgp([
                        Triple(
                            subject: .iri("a"),
                            predicate: .node(.iri(RDF.type)),
                            object: .literal(.withDatatype("1", .integer))
                        ),
                    ])
                )
            )
        let context = Context(prefixMapping: [
            "rdf": RDF.base,
            "xsd": XSD.base,
        ])
        let result = try query.serializeToSPARQL(depth: 0, context: context)
        let expected = """
            SELECT ?a {
              <a> a 1 .
            }

            """
        diffedAssertEqual(
            expected.trimmingCharacters(in: .whitespacesAndNewlines),
            result.trimmingCharacters(in: .whitespacesAndNewlines)
        )

    }

    func testComplex() throws {
        let query =
            Query(op:
                .orderBy(
                    .distinct(
                        .project(
                            ["a"],
                            .union(
                                .minus(
                                    .join(
                                        .filter(
                                            .equals(.node(.variable("a")), .node(.literal(.plain("foo")))),
                                            .bgp([
                                                Triple(
                                                    subject: .iri("a"),
                                                    predicate: .node(.iri(RDF.type)),
                                                    object: .literal(.withDatatype("1", .integer))
                                                ),
                                                Triple(
                                                    subject: .variable("1"),
                                                    predicate: .path(.negated([.forward(RDF.type)])),
                                                    object: .literal(.withLanguage("test", "en"))
                                                ),
                                            ])
                                        ),
                                        .bgp([
                                            Triple(
                                                subject: .variable("a"),
                                                predicate: .node(.variable("b")),
                                                object: .variable("c")
                                            )
                                        ])
                                    ),
                                    .bgp([
                                        Triple(
                                            subject: .iri("x"),
                                            predicate: .node(.iri("y")),
                                            object: .iri("z")
                                        )
                                    ])
                                ),
                                .leftJoin(
                                    .bgp([
                                        Triple(
                                            subject: .iri("a"),
                                            predicate: .node(.iri("b")),
                                            object: .iri("c")
                                        )
                                    ]),
                                    .bgp([
                                        Triple(
                                            subject: .iri("d"),
                                            predicate: .node(.iri("e")),
                                            object: .literal(.withDatatype("1999", .custom(XSD.gYear)))
                                        )
                                    ]),
                                    .node(.literal(.withDatatype("true", .boolean)))
                                )
                            )
                        )
                    ),
                    [
                        OrderComparator(order: .ascending, expression: .node(.variable("a"))),
                        OrderComparator(order: .descending, expression: .node(.variable("b"))),
                    ]
                )
            )
        let context = Context(prefixMapping: [
            "rdf": RDF.base,
            "xsd": XSD.base,
        ])
        let result = try query.serializeToSPARQL(depth: 0, context: context)
        let expected = """
            SELECT DISTINCT ?a {
              {
                <a> a 1 .
                ?1 !a "test"@en .
                FILTER (?a = "foo")
                ?a ?b ?c .
                MINUS {
                  <x> <y> <z> .
                }
              } UNION {
                <a> <b> <c> .
                OPTIONAL {
                  <d> <e> "1999"^^xsd:gYear .
                  FILTER true
                }
              }
            }
            ORDER BY ASC(?a) DESC(?b)
            """
        diffedAssertEqual(
            expected.trimmingCharacters(in: .whitespacesAndNewlines),
            result.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func testNestedProject() throws {
        let query =
            Query(op:
                .project(
                    ["a"],
                    .join(
                        .project(
                            ["b"],
                            .bgp([
                                Triple(
                                    subject: .variable("b"),
                                    predicate: .node(.iri("foo")),
                                    object: .literal(.withLanguage("test", "en"))
                                )
                            ])
                        ),
                        .bgp([
                            Triple(
                                subject: .variable("a"),
                                predicate: .node(.iri("bar")),
                                object: .literal(.withDatatype("1", .integer))
                            )
                        ])
                    )
                )
            )
        let context = Context(prefixMapping: [
            "rdf": RDF.base,
            "xsd": XSD.base,
        ])
        let result = try query.serializeToSPARQL(depth: 0, context: context)
        let expected = """
            SELECT ?a {
              {
                SELECT ?b {
                  ?b <foo> "test"@en .
                }
              }
              ?a <bar> 1 .
            }
            """
        diffedAssertEqual(
            expected.trimmingCharacters(in: .whitespacesAndNewlines),
            result.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func testNestedDistinct() throws {
        let query =
            Query(op:
                .project(
                    ["a"],
                    .join(
                        .distinct(
                            .project(
                                ["b"],
                                .bgp([
                                    Triple(
                                        subject: .variable("b"),
                                        predicate: .node(.iri("foo")),
                                        object: .literal(.withLanguage("test", "en"))
                                    )
                                ])
                            )
                        ),
                        .bgp([
                            Triple(
                                subject: .variable("a"),
                                predicate: .node(.iri("bar")),
                                object: .literal(.withDatatype("1", .integer))
                            )
                        ])
                    )
                )
            )
        let context = Context(prefixMapping: [
            "rdf": RDF.base,
            "xsd": XSD.base,
        ])
        let result = try query.serializeToSPARQL(depth: 0, context: context)
        let expected = """
            SELECT ?a {
              {
                SELECT DISTINCT ?b {
                  ?b <foo> "test"@en .
                }
              }
              ?a <bar> 1 .
            }
            """
        diffedAssertEqual(
            expected.trimmingCharacters(in: .whitespacesAndNewlines),
            result.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func testNestedDirectProject() throws {
        let query =
            Query(op:
                .project(
                    ["a"],
                    .project(
                        ["b"],
                        .bgp([
                            Triple(
                                subject: .variable("b"),
                                predicate: .node(.iri("foo")),
                                object: .literal(.withLanguage("test", "en"))
                            )
                        ])
                    )
                )
            )
        let context = Context(prefixMapping: [
            "rdf": RDF.base,
            "xsd": XSD.base,
        ])
        let result = try query.serializeToSPARQL(depth: 0, context: context)
        let expected = """
            SELECT ?a {
              {
                SELECT ?b {
                  ?b <foo> "test"@en .
                }
              }
            }
            """
        diffedAssertEqual(
            expected.trimmingCharacters(in: .whitespacesAndNewlines),
            result.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func testGroup() throws {
        let query =
            Query(op:
                .project(
                    ["a"],
                    .group(
                        .bgp([
                            Triple(
                                subject: .variable("b"),
                                predicate: .node(.iri("foo")),
                                object: .literal(.withLanguage("test", "en"))
                            )
                        ]),
                        ["b"],
                        ["c": Aggregation(function: .count, distinct: true, variable: "d")]
                    )
                )
            )
        let context = Context(prefixMapping: [
            "rdf": RDF.base,
            "xsd": XSD.base,
        ])
        let result = try query.serializeToSPARQL(depth: 0, context: context)
        let expected = """
            SELECT ?a (COUNT(DISTINCT ?d) AS ?c) {
              ?b <foo> "test"@en .
            }
            GROUP BY ?b
            """
        diffedAssertEqual(
            expected.trimmingCharacters(in: .whitespacesAndNewlines),
            result.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
