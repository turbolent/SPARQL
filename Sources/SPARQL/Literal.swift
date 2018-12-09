
import Foundation

public enum Literal: Hashable {
    case plain(String)
    case withLanguage(String, String)
    case withDatatype(String, Datatype)

    public var value: String {
        switch self {
        case let .plain(value):
            return value

        case .withLanguage(let value, _):
            return value

        case .withDatatype(let value, _):
            return value
        }
    }
}

extension Literal: CustomStringConvertible {

     public var description: String {
        switch self {
        case .plain, .withDatatype(_, .string):
            return valueDescription

        case .withLanguage(_, let language):
            return [valueDescription, language]
                .joined(separator: "@")

        case .withDatatype(_, let datatype):
            return [valueDescription, datatype.description]
                .joined(separator: "^^")
        }
    }

    private var valueDescription: String {
        let escaped = value
            .replacingOccurrences(of:"\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}

extension Literal: SPARQLSerializable {

    public func serializeToSPARQL(depth: Int, context: Context) -> String {
        switch self {
        case .withDatatype(let literal, .integer),
             .withDatatype(let literal, .double),
             .withDatatype(let literal, .boolean):
            return literal

        case .withDatatype(_, let datatype):
            let serializedDatatype =
                datatype.serializeToSPARQL(depth: depth, context: context)
            return [valueDescription, serializedDatatype]
                .joined(separator: "^^")

        default:
            return description
        }
    }
}
