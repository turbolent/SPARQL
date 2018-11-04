import XCTest
@testable import SPARQL
import DiffedAssertEqual

final class SPARQLTests: XCTestCase {

    func testExample() throws {
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
            result.trimmingCharacters(in: .whitespacesAndNewlines),
            expected.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
