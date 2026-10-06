import Foundation
import HeraldCore
import Testing

struct TestEvent: Event {
    let name: String
    var parameters: [String: AnalyticsValue] = [:]
}

struct TestProperty: Property {
    let name: String
    let value: AnalyticsValue
}

/// The message of the failure `assertion` records. The test fails if it records none.
func failureMessage(of assertion: () -> Void) -> String {
    let messages = Messages()
    withKnownIssue {
        assertion()
    } matching: { issue in
        for comment in issue.comments {
            messages.append(comment.rawValue)
        }
        return true
    }
    return messages.joined
}

/// Collects messages from Swift Testing's issue matcher, which may run on another thread. The lock
/// makes that safe, which the compiler can't check: hence `@unchecked Sendable`.
final class Messages: @unchecked Sendable {
    private let lock = NSLock()
    private var messages: [String] = []

    var joined: String {
        lock.lock()
        defer { lock.unlock() }
        return messages.joined(separator: "\n")
    }

    func append(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        messages.append(message)
    }
}
