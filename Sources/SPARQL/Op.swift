
public indirect enum Op {
    case identity
    case bgp([Triple])
    case union(Op, Op)
    case minus(Op, Op)
    case filter(Expression, Op)
    case leftJoin(Op, Op, Expression?)
    case join(Op, Op)
    case project([String], Op)
    case distinct(Op)
    case orderBy(Op, [OrderComparator])
}

extension Op: SPARQLSerializable {

    public enum SPARQLSerializationError: Error {
        case unimplemented
        case unsupportedChildOp
    }

    public func serializeToSPARQL(depth: Int, context: Context) throws -> String {
        let indentation = indent(depth: depth)

        switch self {
        case .identity:
            return ""

        case let .bgp(triples):
            var result = ""
            for triple in triples {
                result += indentation
                result += triple.serializeToSPARQL(depth: depth, context: context)
                result += "\n"
            }
            return result

        case let .union(left, .identity):
            return try left.serializeToSPARQL(depth: depth, context: context)

        case let .union(.identity, right):
            return try right.serializeToSPARQL(depth: depth, context: context)

        case let .union(left, right):
            var result = indentation
            result += "{\n"
            result += try left.serializeToSPARQL(depth: depth + 1, context: context)
            result += indentation
            result += "} UNION {\n"
            result += try right.serializeToSPARQL(depth: depth + 1, context: context)
            result += indentation
            result += "}\n"
            return result

        case let .minus(left, .identity):
            return try left.serializeToSPARQL(depth: depth, context: context)

        case let .minus(.identity, right):
            return try right.serializeToSPARQL(depth: depth, context: context)

        case let .minus(left, right):
            var result = try left.serializeToSPARQL(depth: depth, context: context)
            result += indentation
            result += "MINUS {\n"
            result += try right.serializeToSPARQL(depth: depth + 1, context: context)
            result += indentation
            result += "}\n"
            return result

        case .filter(_, .identity):
            return ""

        case let .filter(expression, op):
            var result = try op.serializeToSPARQL(depth: depth, context: context)
            result += indentation
            result += "FILTER "
            result += try expression.serializeToSPARQL(depth: 0, context: context)
            result += "\n"
            return result

        case let .leftJoin(left, right, expression):
            var result = try left.serializeToSPARQL(depth: depth, context: context)
            result += indentation
            result += "OPTIONAL {\n"
            result += try right.serializeToSPARQL(depth: depth + 1, context: context)
            if let expression = expression {
                result += indentation
                result += "  FILTER "
                result += try expression.serializeToSPARQL(depth: 0, context: context)
                result += "\n"
            }
            result += indentation
            result += "}\n"
            return result

        case let .join(left, right):
            return (try left.serializeToSPARQL(depth: depth, context: context))
                + (try right.serializeToSPARQL(depth: depth, context: context))

        case let .project(variables, op):
            var result = ""
            if variables.isEmpty {
                result += "*"
            } else {
                result += variables
                    .map { name in "?\(name)" }
                    .joined(separator: " ")
            }
            result += " {\n"
            result += try op.serializeToSPARQL(depth: depth + 1, context: context)
            result += indentation
            result += "}\n"
            return result

        case let .distinct(op):
            guard case .project = op else {
                throw SPARQLSerializationError.unsupportedChildOp
            }
            var result = "DISTINCT "
            result += try op.serializeToSPARQL(depth: depth, context: context)
            return result

        case let .orderBy(op, orderComparators):
            guard !orderComparators.isEmpty else {
                return ""
            }
            var result = try op.serializeToSPARQL(depth: depth, context: context)
            result += indentation
            result += "ORDER BY "
            result += try orderComparators
                .map {
                    try $0.serializeToSPARQL(depth: 0, context: context)
                }
                .joined(separator: " ")
            result += "\n"
            return result
        }
    }
}
