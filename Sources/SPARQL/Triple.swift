
public struct Triple: Equatable {

    public var subject: Node
    public var predicate: Predicate
    public var object: Node

    public init(subject: Node, predicate: Predicate, object: Node) {
        self.subject = subject
        self.predicate = predicate
        self.object = object
    }
}

extension Triple: SPARQLSerializable {

    public func serializeToSPARQL(depth: Int, context: Context) -> String {
        let subject = self.subject.serializeToSPARQL(depth: depth, context: context)
        let predicate = self.predicate.serializeToSPARQL(depth: depth, context: context)
        let object = self.object.serializeToSPARQL(depth: depth, context: context)
        return [subject, predicate, object].joined(separator: " ") + " ."
    }
}
