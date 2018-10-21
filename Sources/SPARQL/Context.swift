
public final class Context {
    public var prefixMapping: [String: String]

    public init(prefixMapping: [String: String]) {
        self.prefixMapping = prefixMapping
    }

    func findPrefixMapping(iri: String) -> (prefix: String, suffix: String)? {
        let entry = prefixMapping.first {
            let (_, base) = $0
            return iri.hasPrefix(base)
        }
        guard case let (prefix, base)? = entry else {
            return nil
        }
        let index = iri.index(iri.startIndex, offsetBy: base.count)
        return (prefix, String(iri[index...]))
    }
}
