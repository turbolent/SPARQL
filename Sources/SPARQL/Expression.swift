
public indirect enum Expression: Equatable {
    case node(Node)
    case not(Expression)
    case and(Expression, Expression)
    case or(Expression, Expression)
    case equals(Expression, Expression)
    case notEquals(Expression, Expression)
    case lessThan(Expression, Expression)
    case lessThanOrEquals(Expression, Expression)
    case greaterThan(Expression, Expression)
    case greaterThanOrEquals(Expression, Expression)
}

extension Expression: SPARQLSerializable {

    public func serializeToSPARQL(depth: Int, context: Context) throws -> String {
        switch self {
        case let .node(node):
            return node.serializeToSPARQL(depth: depth, context: context)

        case let .not(expression):
            return "!" + (try expression.serializeToSPARQL(depth: depth, context: context))

        case let .and(left, right):
            let values = try [left, right].map {
                try $0.serializeToSPARQL(depth: depth, context: context)
            }
            return joinAndGroup(values, separator: " && ")

        case let .or(left, right):
            let values = try [left, right].map {
                try $0.serializeToSPARQL(depth: depth, context: context)
            }
            return joinAndGroup(values, separator: " || ")

        case let .equals(left, right):
            let values = try [left, right].map {
                try $0.serializeToSPARQL(depth: depth, context: context)
            }
            return joinAndGroup(values, separator: " = ")

        case let .notEquals(left, right):
            let values = try [left, right].map {
                try $0.serializeToSPARQL(depth: depth, context: context)
            }
            return joinAndGroup(values, separator: " != ")

        case let .lessThan(left, right):
            let values = try [left, right].map {
                try $0.serializeToSPARQL(depth: depth, context: context)
            }
            return joinAndGroup(values, separator: " < ")

        case let .lessThanOrEquals(left, right):
            let values = try [left, right].map {
                try $0.serializeToSPARQL(depth: depth, context: context)
            }
            return joinAndGroup(values, separator: " <= ")

        case let .greaterThan(left, right):
            let values = try [left, right].map {
                try $0.serializeToSPARQL(depth: depth, context: context)
            }
            return joinAndGroup(values, separator: " > ")

        case let .greaterThanOrEquals(left, right):
            let values = try [left, right].map {
                try $0.serializeToSPARQL(depth: depth, context: context)
            }
            return joinAndGroup(values, separator: " >= ")
        }
    }
}
