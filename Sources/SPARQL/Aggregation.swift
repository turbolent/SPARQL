
public enum Aggregation: Hashable {
    case avg(Expression, distinct: Bool)
    case count(Expression?, distinct: Bool)
    case min(Expression, distinct: Bool)
    case max(Expression, distinct: Bool)
    case sample(Expression, distinct: Bool)
    case sum(Expression, distinct: Bool)
    case groupConcat(Expression, distinct: Bool, separator: String?)

    public var distinct: Bool {
        switch self {
        case .avg(_, let distinct),
            .count(_, let distinct),
            .min(_, let distinct),
            .max(_, let distinct),
            .sample(_, let distinct),
            .sum(_, let distinct),
            .groupConcat(_, let distinct, _):

            return distinct
        }
    }

    public var expression: Expression? {
        switch self {
        case .count(let expression, _):
            return expression
        case .avg(let expression, _),
            .min(let expression, _),
            .max(let expression, _),
            .sample(let expression, _),
            .sum(let expression, _),
            .groupConcat(let expression, _, _):

            return expression
        }
    }
}

extension Aggregation: SPARQLSerializable {

    private var sparqlFunctionName: String {
        switch self {
        case .avg:
            return "AVG"
        case .count:
            return "COUNT"
        case .min:
            return "MIN"
        case .max:
            return "MAX"
        case .sample:
            return "SAMPLE"
        case .sum:
            return "SUM"
        case .groupConcat:
            return "GROUP_CONCAT"
        }
    }

    public func serializeToSPARQL(depth: Int, context: Context) throws -> String {
        var inner = distinct ? "DISTINCT " : ""
        if let expression = expression {
            inner += try expression.serializeToSPARQL(depth: 0, context: context)
        } else {
            inner += "*"
        }
        if case let .groupConcat(_, _, separator?) = self {
            let escapedSeparator = separator
                .replacingOccurrences(of:"\"", with: "\\\"")
            inner += "; SEPARATOR=\"\(escapedSeparator)\""
        }
        return "\(sparqlFunctionName)(\(inner))"
    }
}
