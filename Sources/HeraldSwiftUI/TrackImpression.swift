import HeraldCore
import SwiftUI

extension View {
    /// Tracks `event` once, when at least `threshold` of this view is on screen. With a
    /// `minVisibleDuration`, in seconds, it has to stay that visible for that long first; leaving
    /// earlier cancels the count.
    ///
    /// ```swift
    /// OfferCard(offer)
    ///     .trackImpression(
    ///         OfferShown(offerId: offer.id),
    ///         threshold: 0.5,  // half of it on screen
    ///         minVisibleDuration: 1  // for a second, not a fast scroll
    ///     )
    /// ```
    ///
    /// It counts once per appearance: once the view has left the screen completely, coming back
    /// counts again. To count it once per session, keep that rule in the caller.
    ///
    /// "On screen" means inside the window, and on iOS 18 and newer also inside its scroll view, so
    /// a card cut off by a small carousel counts only for its visible part. Something drawn over the
    /// view, such as a sheet, doesn't hide it.
    ///
    /// A different event starts the count again, which is why events here must be `Equatable`.
    ///
    /// `threshold` must be between 0 and 1.
    public func trackImpression<E: Event & Equatable>(
        _ event: E, threshold: Double = 0.5, minVisibleDuration: TimeInterval = 0
    ) -> some View {
        precondition(
            threshold >= 0 && threshold <= 1,
            "The impression threshold must be between 0 and 1, not \(threshold).")
        return modifier(
            ImpressionModifier(
                event: event, threshold: threshold, minVisibleDuration: minVisibleDuration))
    }
}

private struct ImpressionModifier<E: Event & Equatable>: ViewModifier {
    let event: E
    let threshold: Double
    let minVisibleDuration: TimeInterval

    @Environment(\.eventTracker) private var tracker
    @State private var impression = ImpressionState(threshold: 0.5, minVisibleDuration: 0)
    @State private var wait: Task<Void, Never>?
    @State private var window = WindowReader()

    func body(content: Content) -> some View {
        scrollVisibility(
            content
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { frameChanged(proxy.frame(in: .global)) }
                            .onChange(of: proxy.frame(in: .global)) { frame in
                                frameChanged(frame)
                            }
                    }
                )
                .background(WindowReaderView(reader: window))
        )
        .onAppear {
            window.onAttach = { frameChanged(window.lastFrame) }
            update { impression in impression.appeared() }
        }
        .onDisappear { update { impression in impression.disappeared() } }
        .onChange(of: event) { _ in update { impression in impression.eventChanged() } }
    }

    /// On iOS 18 and newer, also follows how much of the view its scroll view shows.
    @ViewBuilder
    private func scrollVisibility(_ content: some View) -> some View {
        if #available(iOS 18, macOS 15, *) {
            content
                .onScrollVisibilityChange(threshold: max(threshold, 0.001)) { visible in
                    update { impression in
                        impression.scrollVisibilityChanged(aboveThreshold: visible)
                    }
                }
                .onScrollVisibilityChange(threshold: 0.001) { visible in
                    update { impression in impression.scrollPresenceChanged(partlyVisible: visible)
                    }
                }
        } else {
            content
        }
    }

    private func frameChanged(_ frame: CGRect?) {
        window.lastFrame = frame
        guard let frame, let bounds = window.bounds else {
            return  // not in a window yet
        }
        let fraction = visibleFraction(of: frame, in: bounds)
        update { impression in impression.windowFractionChanged(to: fraction) }
    }

    /// Applies one change to the impression, then does what it asks.
    private func update(_ change: (inout ImpressionState) -> ImpressionState.Action) {
        if isRunningInPreview {
            return
        }
        impression.threshold = threshold
        impression.minVisibleDuration = minVisibleDuration
        switch change(&impression) {
        case .none:
            break
        case .track:
            wait?.cancel()
            tracker.track(event)
        case .startWaiting:
            wait?.cancel()
            let seconds = minVisibleDuration
            wait = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                if !Task.isCancelled {
                    update { impression in impression.waited() }
                }
            }
        case .stopWaiting:
            wait?.cancel()
            wait = nil
        }
    }
}
