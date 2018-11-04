
public indirect enum Op: Equatable {
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

        func nest(_ serializable: SPARQLSerializable, depth: Int) throws -> String {
            return try serializable.serializeToSPARQL(depth: depth, context: context)
        }

        switch self {
        case .identity:
            return ""

        case let .bgp(triples):
            var result = ""
            for triple in triples {
                result += indentation
                result += try nest(triple, depth: depth)
                result += "\n"
            }
            return result

        case let .union(left, .identity):
            return try nest(left, depth: depth)

        case let .union(.identity, right):
            return try nest(right, depth: depth)

        case let .union(left, right):
            var result = indentation
            result += "{\n"
            result += try nest(left, depth: depth + 1)
            result += indentation
            result += "} UNION {\n"
            result += try nest(right, depth: depth + 1)
            result += indentation
            result += "}\n"
            return result

        case let .minus(left, .identity):
            return try nest(left, depth: depth)

        case let .minus(.identity, right):
            return try nest(right, depth: depth)

        case let .minus(left, right):
            var result = try nest(left, depth: depth)
            result += indentation
            result += "MINUS {\n"
            result += try nest(right, depth: depth + 1)
            result += indentation
            result += "}\n"
            return result

        case .filter(_, .identity):
            return ""

        case let .filter(expression, op):
            var result = try nest(op, depth: depth)
            result += indentation
            result += "FILTER "
            result += try nest(expression, depth: 0)
            result += "\n"
            return result

        case let .leftJoin(left, right, expression):
            var result = try nest(left, depth: depth)
            result += indentation
            result += "OPTIONAL {\n"
            result += try nest(right, depth: depth + 1)
            if let expression = expression {
                result += indentation
                result += "  FILTER "
                result += try nest(expression, depth: 0)
                result += "\n"
            }
            result += indentation
            result += "}\n"
            return result

        case let .join(left, right):
            var result = try nest(left, depth: depth)
            result += try nest(right, depth: depth)
            return result

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
            result += try nest(op, depth: depth + 1)
            result += indentation
            result += "}\n"
            return result

        case let .distinct(op)
            where op.isValidDistinctChild:

            var result = "DISTINCT "
            result += try nest(op, depth: depth)
            return result

        case .distinct:
            // fall-through for distinct child ops which are invalid
            throw SPARQLSerializationError.unsupportedChildOp

        case let .orderBy(op, orderComparators)
            where op.isValidOrderByChild:

            if orderComparators.isEmpty {
                return try nest(op, depth: depth)
            }
            var result = try nest(op, depth: depth)
            result += indentation
            result += "ORDER BY "
            result += try orderComparators
                .map { try nest($0, depth: 0) }
                .joined(separator: " ")
            result += "\n"
            return result

        case .orderBy:
            // fall-through for orderBy child ops which are invalid
            throw SPARQLSerializationError.unsupportedChildOp
        }
    }

    public var isValidDistinctChild: Bool {
        switch self {
        case .project, .orderBy:
            return true
        default:
            return false
        }
    }

    public var isValidOrderByChild: Bool {
        switch self {
        case .project, .distinct:
            return true
        default:
            return false
        }
    }
}

