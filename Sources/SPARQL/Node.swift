
public enum Node: Hashable {
    case variable(String)
    case blank(String)
    case iri(String)
    case literal(Literal)

    public static var `true`: Node {
        return .literal(.withDatatype("true", Datatype.boolean))
    }

    public static var `false`: Node {
        return .literal(.withDatatype("false", Datatype.boolean))
    }
}

extension Node: CustomStringConvertible {

    public var description: String {
        switch self {
        case let .variable(name):
            return "?\(name)"
        case let .blank(id):
            return "_:\(id)"
        case .iri(RDF.type):
            return "a"
        case let .iri(iri):
            return "<\(iri)>"
        case let .literal(literal):
            return literal.description
        }
    }
}

extension Node: SPARQLSerializable {

    public func serializeToSPARQL(depth: Int, context: Context) -> String {
        if self == .iri(RDF.type) {
            return "a"
        }

        if case let .iri(iri) = self,
            let (prefix, suffix) = context.findPrefixMapping(iri: iri)
        {
            return "\(prefix):\(suffix)"
        }

        if case let .literal(literal) = self {
            return literal.serializeToSPARQL(depth: depth, context: context)
        }
        
        return description
    }
}
