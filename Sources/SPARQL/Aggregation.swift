
public enum AggregateFunction: String, Equatable {
    case avg
    case count
    case sum
}

public struct Aggregation: Equatable {
    public var function: AggregateFunction
    public var distinct: Bool
    public var variable: String?

    public init(
        function: AggregateFunction,
        distinct: Bool,
        variable: String?)
    {
        self.function = function
        self.distinct = distinct
        self.variable = variable
    }
}

extension Aggregation: SPARQLSerializable {

    public func serializeToSPARQL(depth: Int, context: Context) -> String {
        var inner = distinct ? "DISTINCT " : ""
        if let variable = variable {
            inner += "?\(variable)"
        } else {
            inner += "*"
        }
        let outer = function.rawValue.uppercased()
        return "\(outer)(\(inner))"
    }
}
