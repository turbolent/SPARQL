
public enum NegatedIRI: Equatable {
    case forward(String)
    case reverse(String)

    public var iri: String {
        switch self {
        case let .forward(iri):
            return iri
        case let .reverse(iri):
            return iri
        }
    }
}

extension NegatedIRI: CustomStringConvertible {

    public var description: String {
        let serialized = "<\(iri)>"
        switch self {
        case .forward:
            return serialized
        case .reverse:
            return "^\(serialized)"
        }
    }
}

extension NegatedIRI: SPARQLSerializable {

    public func serializeToSPARQL(depth: Int, context: Context) -> String {
        let iri = self.iri
        let serialized: String
        if iri == RDF.type {
            serialized = "a"
        } else if let (prefix, suffix) = context.findPrefixMapping(iri: iri) {
             serialized = "\(prefix):\(suffix)"
        } else {
            serialized = "<\(iri)>"
        }
        switch self {
        case .forward:
            return serialized
        case .reverse:
            return "^\(serialized)"
        }
    }
}
