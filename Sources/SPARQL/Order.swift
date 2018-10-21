
public enum Order: Equatable {
    case ascending
    case descending
}

extension Order: SPARQLSerializable {

    public func serializeToSPARQL(depth: Int, context: Context) throws -> String {
        switch self {
        case .ascending:
            return "ASC"
        case .descending:
            return "DESC"
        }
    }
}
