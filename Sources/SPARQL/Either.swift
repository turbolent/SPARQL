public enum Predicate: Equatable {
    case node(Node)
    case path(Path)
}

extension Predicate: SPARQLSerializable  {
    public func serializeToSPARQL(depth: Int, context: Context) -> String {
        switch self {
        case let .node(node):
            return node.serializeToSPARQL(depth: depth, context: context)
        case let .path(path):
            return path.serializeToSPARQL(depth: depth, context: context)
        }
    }
}
