import Foundation
import HeraldCore

/// Lets Kotlin Multiplatform code use a ``Herald`` set up in Swift.
///
/// Kotlin can call it because it's visible to Objective-C. Each call becomes an ordinary Herald
/// event or property, so vendors treat it as if Swift had sent it.
@objc(HRBHerald)
public final class HeraldBridge: NSObject, Sendable {
    /// Turns a Kotlin event into a herald-ios one, such as a revenue event, or returns nil to track
    /// it as a plain event. The parameters are already in Swift.
    public typealias Translation =
        @Sendable (_ kotlinEvent: AnyObject, _ parameters: [String: AnalyticsValue]) -> (any Event)?

    private let herald: Herald
    private let translate: Translation?
    private let errorReporter: AnalyticsErrorReporter?

    /// `translate` turns vendor events from Kotlin, such as revenue, into the herald-ios types
    /// their vendors recognise. herald-kmp's `RevenueTranslation.swift` is a ready one to copy.
    ///
    /// A vendor event `translate` misses goes to `errorReporter`, and is still tracked as a plain
    /// event. Without an `errorReporter`, it stops a debug build instead.
    public init(
        _ herald: Herald, translate: Translation? = nil,
        errorReporter: AnalyticsErrorReporter? = nil
    ) {
        self.herald = herald
        self.errorReporter = errorReporter
        self.translate = translate
    }

    /// Tracks an event. `kotlinEvent` is the original Kotlin object, so factories can check its
    /// labels. `needsTranslation` marks a vendor event that `translate` must handle.
    @objc public func track(
        name: String, parameters: [String: BridgeValue], isScreenView: Bool,
        needsTranslation: Bool, kotlinEvent: AnyObject
    ) {
        let values = parameters.mapValues { parameter in parameter.value }
        if let translated = translate?(kotlinEvent, values) {
            herald.track(translated)
            return
        }
        if needsTranslation {
            reportUntranslated(name: name, kotlinEvent: kotlinEvent)
        }
        if isScreenView {
            herald.track(
                BridgedScreenViewEvent(name: name, parameters: values, source: kotlinEvent))
        } else {
            herald.track(BridgedEvent(name: name, parameters: values, source: kotlinEvent))
        }
    }

    @objc public func set(name: String, value: BridgeValue, isUserProperty: Bool) {
        if isUserProperty {
            herald.set(BridgedUserProperty(name: name, value: value.value))
        } else {
            herald.set(BridgedProperty(name: name, value: value.value))
        }
    }

    @objc public func identify(userId: String) { herald.identify(Identity(userId: userId)) }

    @objc public func reset() { herald.reset() }

    @objc public func start() { herald.start() }

    @objc public func flush() { herald.flush() }

    @objc public func setEnabled(_ enabled: Bool) { herald.setEnabled(enabled) }

    private func reportUntranslated(name: String, kotlinEvent: AnyObject) {
        let error = UntranslatedEvent(kotlinType: String(describing: type(of: kotlinEvent)))
        guard let errorReporter else {
            assertionFailure("\(error)")
            return
        }
        errorReporter(
            AnalyticsFailure(
                provider: "HeraldBridge", operation: .track(eventName: name), error: error))
    }
}

/// A vendor event from Kotlin that `translate` didn't turn into its herald-ios type.
struct UntranslatedEvent: Error, CustomStringConvertible {
    let kotlinType: String

    var description: String {
        "\(kotlinType) has no translation, so its vendor gets it as a plain event. Add its block "
            + "to the translate function, as in herald-kmp's RevenueTranslation.swift."
    }
}

/// A value that keeps its type on the way from Kotlin. An `NSNumber` would lose whether 3 was an
/// Int, a Double or a Bool.
@objc(HRBValue)
public final class BridgeValue: NSObject, Sendable {
    let value: AnalyticsValue

    private init(_ value: AnalyticsValue) {
        self.value = value
    }

    @objc public static func string(_ value: String) -> BridgeValue { BridgeValue(.string(value)) }

    @objc public static func int(_ value: Int) -> BridgeValue { BridgeValue(.int(value)) }

    @objc public static func double(_ value: Double) -> BridgeValue { BridgeValue(.double(value)) }

    @objc public static func bool(_ value: Bool) -> BridgeValue { BridgeValue(.bool(value)) }
}

// Kotlin objects aren't marked Sendable, but a tracked event never changes, so sharing it is
// safe: hence `@unchecked Sendable`.

/// An event that came through the bridge.
public struct BridgedEvent: Event, @unchecked Sendable {
    public let name: String
    public let parameters: [String: AnalyticsValue]
    let source: AnyObject
}

/// A screen view that came through the bridge.
public struct BridgedScreenViewEvent: ScreenViewEvent, @unchecked Sendable {
    public let name: String
    public let parameters: [String: AnalyticsValue]
    let source: AnyObject
}

extension Event {
    /// The Kotlin object this event came from, or nil for an event tracked from Swift. Check your
    /// shared labels on it:
    ///
    /// ```swift
    /// if event.kotlinEvent is PersonalDataEvent {
    ///     return .dropped
    /// }
    /// ```
    public var kotlinEvent: AnyObject? {
        if let event = self as? BridgedEvent {
            return event.source
        }
        if let event = self as? BridgedScreenViewEvent {
            return event.source
        }
        return nil
    }
}

public struct BridgedProperty: Property {
    public let name: String
    public let value: AnalyticsValue
}

public struct BridgedUserProperty: UserProperty {
    public let name: String
    public let value: AnalyticsValue
}
