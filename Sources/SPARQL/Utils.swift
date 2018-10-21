
internal func joinAndGroup(_ values: [String], separator: String) -> String {
    if values.count < 2 {
        return values.first ?? ""
    }

    let joined = values
        .joined(separator: separator)
    return "(\(joined))"
}

internal func indent(depth: Int) -> String {
    return String(repeating: " ", count: depth * 2)
}
