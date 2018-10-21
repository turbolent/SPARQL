
public struct OrderComparator {

    public var order: Order
    public var expression: Expression

    public init(order: Order, expression: Expression) {
        self.order = order
        self.expression = expression
    }
}

extension OrderComparator: SPARQLSerializable {

    public func serializeToSPARQL(depth: Int, context: Context) throws -> String {
        let serializedOrder =
            try order.serializeToSPARQL(depth: 0, context: context)
        let serializedExpression =
            try expression.serializeToSPARQL(depth: 0, context: context)
        return "\(serializedOrder)(\(serializedExpression))"
    }
}
