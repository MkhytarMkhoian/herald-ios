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

    /// Tracks an event. A `"screen_view"` marker makes it a ``ScreenViewEvent``. Other markers are
    /// kept on the ``BridgedEvent`` for your own factories to read.
    @objc public func track(name: String, parameters: [String: BridgeValue], markers: Set<String>) {
        let values = parameters.mapValues { parameter in parameter.value }
        if markers.contains(BridgedScreenViewEvent.marker) {
            herald.track(BridgedScreenViewEvent(name: name, parameters: values, markers: markers))
        } else {
            herald.track(BridgedEvent(name: name, parameters: values, markers: markers))
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

/// An event that came through the bridge. Your own factories can match its markers.
public struct BridgedEvent: Event {
    public let name: String
    public let parameters: [String: AnalyticsValue]
    public let markers: Set<String>
}

/// A screen view that came through the bridge, with the `"screen_view"` marker.
public struct BridgedScreenViewEvent: ScreenViewEvent {
    static let marker = "screen_view"

    public let name: String
    public let parameters: [String: AnalyticsValue]
    public let markers: Set<String>
}

public struct BridgedProperty: Property {
    public let name: String
    public let value: AnalyticsValue
}

public struct BridgedUserProperty: UserProperty {
    public let name: String
    public let value: AnalyticsValue
}
