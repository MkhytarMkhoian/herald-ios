import Foundation
import HeraldCore
import SwiftUI

extension EnvironmentValues {
    /// The tracker used by ``SwiftUI/View/trackScreenView(_:)``,
    /// ``SwiftUI/View/track(_:on:)`` and ``SwiftUI/View/trackImpression(_:threshold:minVisibleDuration:)``,
    /// and by your own views for taps:
    ///
    /// ```swift
    /// struct PromoBanner: View {
    ///     let promo: Promo
    ///     @Environment(\.eventTracker) private var analytics
    ///
    ///     var body: some View {
    ///         Button("See the offer") {
    ///             analytics.track(PromoBannerTapped(promoId: promo.id))
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// Set it once, at the root, with ``SwiftUI/View/eventTracker(_:)``.
    public var eventTracker: any EventTrackerService {
        get { self[EventTrackerKey.self] }
        set { self[EventTrackerKey.self] = newValue }
    }
}

extension View {
    /// Gives `tracker` to this view and every view inside it. Call it once, at the root:
    ///
    /// ```swift
    /// WindowGroup {
    ///     RootView()
    ///         .eventTracker(herald)
    /// }
    /// ```
    public func eventTracker(_ tracker: any EventTrackerService) -> some View {
        environment(\.eventTracker, tracker)
    }
}

private struct EventTrackerKey: EnvironmentKey {
    static let defaultValue: any EventTrackerService = MissingEventTracker()
}

/// Stands in until the app sets a tracker. Tracking through it stops a debug build, and drops the
/// event in a release build.
struct MissingEventTracker: EventTrackerService {
    func track(_ event: any Event) {
        if isRunningInPreview {
            return
        }
        assertionFailure(
            "No tracker for '\(event.name)'. Add .eventTracker(herald) at the root of your views.")
    }
}

/// True in Xcode Previews, where the helpers track nothing.
let isRunningInPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
