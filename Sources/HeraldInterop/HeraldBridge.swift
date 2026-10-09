import Foundation
import HeraldCore

/// Lets code that can't call Swift, such as Kotlin Multiplatform, use a ``Herald`` set up in Swift.
///
/// Everything here is visible to Objective-C, and so to Kotlin. Each call becomes an ordinary
/// Herald event or property, so the vendors' factories treat it as if Swift had sent it:
///
/// ```swift
/// let herald = Herald(providers: [firebaseProvider()])
/// let bridge = HeraldBridge(herald)  // hand this to the shared code
/// ```
@objc(HRBHerald)
public final class HeraldBridge: NSObject, Sendable {
    private let herald: Herald

    public init(_ herald: Herald) {
        self.herald = herald
    }

    /// Tracks an event. `kotlinEvent` is the original Kotlin object: your own factories check its
    /// labels with ``HeraldCore/Event/kotlinEvent``.
    @objc public func track(
        name: String, parameters: [String: BridgeValue], isScreenView: Bool, kotlinEvent: AnyObject
    ) {
        let values = parameters.mapValues { parameter in parameter.value }
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
}

/// A typed value Objective-C can carry. An `NSNumber` can't: it forgets whether 3 was an Int, a
/// Double or a Bool, and Herald keeps them apart.
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

// Kotlin objects aren't marked Sendable, but a tracked event never changes, so it's safe to share:
// hence `@unchecked Sendable` on the two event types.

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
    /// The Kotlin object this event was made from, or nil for an event tracked from Swift. Check
    /// your shared labels on it:
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
