
public enum Datatype: Equatable {
    case string
    case boolean
    case integer
    case float
    case double
    case decimal
    case date
    case dateTime
    case custom(String)

    public var iri: String {
        switch self {
        case .string:
            return XSD.string
        case .boolean:
            return XSD.boolean
        case .integer:
            return XSD.integer
        case .float:
            return XSD.float
        case .double:
            return XSD.double
        case .decimal:
            return XSD.decimal
        case .date:
            return XSD.date
        case .dateTime:
            return XSD.dateTime
        case .custom(let iri):
            return iri
        }
    }

    public init(iri: String) {
        switch iri {
        case XSD.string:
            self = .string
        case XSD.boolean:
            self = .boolean
        case XSD.integer:
            self = .integer
        case XSD.float:
            self = .float
        case XSD.double:
            self = .double
        case XSD.decimal:
            self = .decimal
        case XSD.date:
            self = .date
        case XSD.dateTime:
            self = .dateTime
        default:
            self = .custom(iri)
        }
    }
}

extension Datatype: CustomStringConvertible{

    public var description: String {
        return "<\(iri)>"
    }
}

extension Datatype: SPARQLSerializable {

    public func serializeToSPARQL(depth: Int, context: Context) -> String {
        if let (prefix, suffix) = context.findPrefixMapping(iri: iri) {
            return "\(prefix):\(suffix)"
        }
        return description
    }
}

