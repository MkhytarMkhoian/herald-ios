import HeraldCore

/// Starts every record, so Herald's lines are easy to filter.
let logTag = "[herald]"

/// Length of the longest kind, `enabled`, so headlines line up.
private let kindWidth = 7

/// Renders one record as one string: a header line, then a branch per parameter with the last one
/// closed by `└─`, values aligned on the longest key.
///
/// One string, and one log call, so a record can't be split by another one. A record with no
/// headline (`reset`, `start`, `flush`) is the bare kind.
func logRecord(
    kind: String, headline: String, parameters: [String: AnalyticsValue] = [:]
) -> String {
    var record = "\(logTag) "
    if headline.isEmpty {
        record += kind
    } else {
        record += "\(padded(kind, to: kindWidth)) \(headline)"
    }
    let keys = parameters.keys.sorted()
    let keyWidth = keys.map { key in key.count }.max() ?? 0
    for key in keys {
        let branch = key == keys.last ? "└─" : "├─"
        record += "\n    \(branch) \(padded(key, to: keyWidth)) = \(parameters[key]!.asString)"
    }
    return record
}

private func padded(_ text: String, to width: Int) -> String {
    text + String(repeating: " ", count: max(0, width - text.count))
}
