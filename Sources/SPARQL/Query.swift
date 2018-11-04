public struct Query: Equatable {

    public var op: Op

    public init(op: Op) {
        self.op = op
    }
}

extension Query: SPARQLSerializable {

    public func serializeToSPARQL(depth: Int, context: Context) throws -> String {
        let indentation = indent(depth: depth)
        var result = indentation
        result += "SELECT "
        switch op {
        case .orderBy, .project, .distinct:
            result += try op.serializeToSPARQL(depth: depth, context: context)
        default:
            result += "* {\n"
            result += try op.serializeToSPARQL(depth: depth + 1, context: context)
            result += indentation
            result += "}\n"
        }
        return result
    }
}
