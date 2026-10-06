import Foundation
import HeraldCore
import HeraldLog

struct TestEvent: Event {
    let name: String
    var parameters: [String: AnalyticsValue] = [:]
}

struct TestScreenView: ScreenViewEvent {
    let name: String
    var parameters: [String: AnalyticsValue] = [:]
}

struct TestProperty: Property {
    let name: String
    let value: AnalyticsValue
}

struct TestError: Error {}

/// What the log adapter printed. The lock lets a logger closure append from any thread, which the
/// compiler can't check: hence `@unchecked Sendable`.
final class Printed: @unchecked Sendable {
    private let lock = NSLock()
    private var printedLines: [String] = []

    var lines: [String] {
        lock.lock()
        defer { lock.unlock() }
        return printedLines
    }

    var logger: AnalyticsLogger {
        { message in self.append(message) }
    }

    private func append(_ line: String) {
        lock.lock()
        defer { lock.unlock() }
        printedLines.append(line)
    }
}

/// What a test tracker does: print a message, or fail.
enum Step: Sendable {
    case print(String)
    case fail
}

struct StepLogEventTracker: LogEventTracker {
    let step: Step
    let logger: AnalyticsLogger

    func track() throws {
        switch step {
        case .print(let message):
            logger(message)
        case .fail:
            throw TestError()
        }
    }
}

/// Claims events called `name` with one tracker per step, and declines the rest.
struct ClaimingLogEventTrackerFactory: LogEventTrackerFactory {
    let name: String
    let steps: [Step]
    let logger: AnalyticsLogger

    func create(_ event: any Event) -> Resolution<any LogEventTracker> {
        if event.name != name {
            return .declined
        }
        var trackers: [any LogEventTracker] = []
        for step in steps {
            trackers.append(StepLogEventTracker(step: step, logger: logger))
        }
        return .claimed(trackers)
    }
}

/// What Herald sent to its error reporter. Locked like ``Printed``.
final class ReportedFailures: @unchecked Sendable {
    private let lock = NSLock()
    private var failures: [AnalyticsFailure] = []

    var all: [AnalyticsFailure] {
        lock.lock()
        defer { lock.unlock() }
        return failures
    }

    func append(_ failure: AnalyticsFailure) {
        lock.lock()
        defer { lock.unlock() }
        failures.append(failure)
    }
}
