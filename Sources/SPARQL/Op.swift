
// possible nesting: distinct? project orderBy? filter? group?

public indirect enum Op: Equatable {
    case identity
    case distinct(Op)
    case project([String], Op)
    case orderBy(Op, [OrderComparator])
    case filter(Expression, Op)
    case group(Op, [String], [String: Aggregation])
    case bgp([Triple])
    case union(Op, Op)
    case minus(Op, Op)
    case leftJoin(Op, Op, Expression?)
    case join(Op, Op)
}

extension Op: SPARQLSerializable {

    public enum SPARQLSerializationError: Error {
        case unimplemented
        case unsupportedChildOp
    }

    public func serializeToSPARQL(depth: Int, context: Context) throws -> String {
        let indentation = indent(depth: depth)

        func nest(_ nested: SPARQLSerializable, depth: Int) throws -> String {
            var depth = depth
            var result = ""
            let nestedOp = nested as? Op
            let isSubquery = nestedOp
                .map { self.isSubquery(nested: $0) }
                ?? false
            let indentation = indent(depth: depth)
            if isSubquery {
                result += indentation
                result += "{\n"
                result += indentation
                result += "  SELECT "
                depth += 1
            }

            if nestedOp?.isHaving(parent: self) ?? false,
                case let .filter(expression, op)? = nestedOp
            {
                // if child op is group it will add the block
                switch op {
                case .group:
                    result += try nest(op, depth: depth)
                default:
                    result += " {\n"
                    result += try nest(op, depth: depth + 1)
                    result += indentation
                    result += "}\n"
                }
                result += indentation
                result += "HAVING "
                result += try nest(expression, depth: 0)
                result += "\n"
            } else {
                result += try nested.serializeToSPARQL(depth: depth, context: context)
            }

            if isSubquery {
                result += indentation
                result += "}\n"
            }
            return result
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

            // if child op is a filter which will result in a HAVING clause, a group, or an order by,
            // it will add the block
            switch op {
            case .filter where op.isHaving(parent: self), .group, .orderBy:
                result += try nest(op, depth: depth)
            default:
                result += " {\n"
                result += try nest(op, depth: depth + 1)
                result += indentation
                result += "}\n"
            }

            return result

        case let .distinct(op)
            where op.isValidDistinctChild:

            var result = "DISTINCT "
            result += try nest(op, depth: depth)
            return result

        case .distinct:
            // fall-through for distinct child ops which are invalid
            throw SPARQLSerializationError.unsupportedChildOp

        case let .orderBy(op, orderComparators):
            var result = ""

            // if child op is filter which will result in a HAVING clause, or a group, it will add the block
            switch op {
            case .filter where op.isHaving(parent: self), .group:
                result += try nest(op, depth: depth)
            default:
                result += " {\n"
                result += try nest(op, depth: depth + 1)
                result += indentation
                result += "}\n"
            }

            if orderComparators.isEmpty {
                return result
            }
            result += indentation
            result += "ORDER BY "
            result += try orderComparators
                .map { try nest($0, depth: 0) }
                .joined(separator: " ")
            result += "\n"
            return result

        case let .group(op, groupVars, aggregations):
            var result = try aggregations
                .sorted { $0.key < $1.key }
                .map {
                    let (name, aggregation) = $0
                    let serialized = try nest(aggregation, depth: 0)
                    return " (\(serialized) AS ?\(name))"
                }
                .joined()

            // if child op is filter which will result in a HAVING clause, or an order by,
            // it will add the block
            switch op {
            case .filter where op.isHaving(parent: self), .orderBy:
                result += try nest(op, depth: depth)
            default:
                result += " {\n"
                result += try nest(op, depth: depth + 1)
                result += indentation
                result += "}\n"
            }

            if !groupVars.isEmpty {
                result += indentation
                result += "GROUP BY "
                result += groupVars
                    .map { name in "?\(name)" }
                    .joined(separator: " ")
            }
            result += "\n"
            return result
        }
    }

    public var isValidDistinctChild: Bool {
        guard case .project = self else {
            return false
        }
        return true
    }

    public var isQuery: Bool {
        switch self {
        case .distinct, .project:
            return true
        default:
            return false
        }
    }

    public func isSubquery(nested: Op) -> Bool {
        switch self {
        case .distinct:
            return false
        default:
            return nested.isQuery
        }
    }

    public func isHaving(parent: Op) -> Bool {
        guard case let .filter(_, child) = self else {
            return false
        }
        switch parent {
        case .orderBy, .project:
            guard case .group = child else {
                return false
            }
            return true
        default:
            return false
        }
    }
}

