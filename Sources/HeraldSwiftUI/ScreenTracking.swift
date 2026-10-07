import HeraldCore
import SwiftUI

/// When ``SwiftUI/View/track(_:on:)`` tracks.
public enum ScreenMoment: Sendable {
    /// The screen became visible: it appeared, the user came back to it, or the app came back from
    /// the background with it on top.
    case visible
    /// The screen stopped being visible: another screen opened over it, it closed, or the app went
    /// to the background.
    case hidden
}

extension View {
    /// Tracks `event` each time this screen becomes visible: when it appears, when the user comes
    /// back to it, and when the app comes back from the background with it on top. That is what
    /// Firebase's automatic screen tracking counts.
    ///
    /// ```swift
    /// ProductDetails(productId)
    ///     .trackScreenView(ProductScreenViewed(productId: productId))
    /// ```
    ///
    /// Redraws don't count, and neither do sheets or alerts over the screen, nor the app briefly
    /// losing focus, as under Notification Center. A tab counts each time it's selected.
    ///
    /// Put it on the screen's root view, not on a row of a list: a row appears each time it
    /// scrolls into view.
    public func trackScreenView(_ event: any ScreenViewEvent) -> some View {
        track(event, on: .visible)
    }

    /// Tracks `event` each time this screen reaches `moment`. Use `.hidden` to track when the user
    /// leaves it:
    ///
    /// ```swift
    /// CheckoutView(cart)
    ///     .track(CheckoutLeft(itemsInCart: cart.count), on: .hidden)
    /// ```
    public func track(_ event: any Event, on moment: ScreenMoment) -> some View {
        modifier(ScreenTrackingModifier(event: event, moment: moment))
    }
}

private struct ScreenTrackingModifier: ViewModifier {
    let event: any Event
    let moment: ScreenMoment

    @Environment(\.eventTracker) private var tracker
    @Environment(\.scenePhase) private var scenePhase
    @State private var screen = ScreenState()

    func body(content: Content) -> some View {
        content
            .onAppear { report(screen.appeared(inBackground: scenePhase == .background)) }
            .onDisappear { report(screen.disappeared()) }
            .onChange(of: scenePhase) { phase in report(screen.phaseChanged(to: phase)) }
    }

    private func report(_ reached: ScreenMoment?) {
        if reached == moment && !isRunningInPreview {
            tracker.track(event)
        }
    }
}

/// Follows one screen's appear, disappear and app phase calls, and says which ``ScreenMoment``
/// each one makes, if any.
struct ScreenState {
    private var isOnScreen = false
    private var isInBackground = false

    mutating func appeared(inBackground: Bool) -> ScreenMoment? {
        if isOnScreen {
            return nil  // SwiftUI sometimes calls onAppear twice
        }
        isOnScreen = true
        isInBackground = inBackground
        return isInBackground ? nil : .visible
    }

    mutating func disappeared() -> ScreenMoment? {
        if !isOnScreen {
            return nil
        }
        isOnScreen = false
        return isInBackground ? nil : .hidden
    }

    mutating func phaseChanged(to phase: ScenePhase) -> ScreenMoment? {
        switch phase {
        case .background:
            if isInBackground {
                return nil
            }
            isInBackground = true
            return isOnScreen ? .hidden : nil
        case .active:
            if !isInBackground {
                return nil
            }
            isInBackground = false
            return isOnScreen ? .visible : nil
        case .inactive:
            return nil  // only focus lost, as under Notification Center: still in view
        @unknown default:
            return nil
        }
    }
}
