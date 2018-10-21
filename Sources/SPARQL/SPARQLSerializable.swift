
public protocol SPARQLSerializable {
    func serializeToSPARQL(depth: Int, context: Context) throws -> String
}
