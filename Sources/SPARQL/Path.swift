
public indirect enum Path: Equatable {
    case predicate(String)
    case inverse(Path)
    case sequence([Path])
    case alternative([Path])
    case zeroOrMore(Path)
    case oneOrMore(Path)
    case zeroOrOne(Path)
    case negated([NegatedIRI])
}

extension Path: SPARQLSerializable {
    
    public func serializeToSPARQL(depth: Int, context: Context) -> String {
        switch self {
        case .predicate(RDF.type):
            return "a"
        case let .predicate(iri):
            if let (prefix, suffix) = context.findPrefixMapping(iri: iri) {
                return "\(prefix):\(suffix)"
            }
            return "<\(iri)>"

        case let .inverse(path):
            let serialized = path.serializeToSPARQL(depth: depth, context: context)
            return "^\(serialized)"

        case let .sequence(paths):
            let serialized = paths.map {
                $0.serializeToSPARQL(depth: depth, context: context)
            }
            return joinAndGroup(serialized, separator: " / ")

        case let .alternative(paths):
            let serialized = paths.map {
                $0.serializeToSPARQL(depth: depth, context: context)
            }
            return joinAndGroup(serialized, separator: " | ")

        case let .zeroOrMore(path):
            let serialized = path.serializeToSPARQL(depth: depth, context: context)
            return "\(serialized)*"

        case let .oneOrMore(path):
            let serialized = path.serializeToSPARQL(depth: depth, context: context)
            return "\(serialized)+"

        case let .zeroOrOne(path):
            let serialized = path.serializeToSPARQL(depth: depth, context: context)
            return "\(serialized)?"

        case let .negated(negatedIRIs):
            let serialized = negatedIRIs.map {
                $0.serializeToSPARQL(depth: depth, context: context)
            }
            let joined = joinAndGroup(serialized, separator: " | ")
            return "!\(joined)"
        }
    }
}
