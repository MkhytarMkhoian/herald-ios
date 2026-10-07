import CoreGraphics
import Testing

@testable import HeraldSwiftUI

@Suite struct ImpressionStateTests {
    private func onScreen(
        threshold: Double = 0.5, minVisibleDuration: Double = 0
    ) -> ImpressionState {
        var impression = ImpressionState(
            threshold: threshold, minVisibleDuration: minVisibleDuration)
        _ = impression.appeared()
        return impression
    }

    @Test func tracksOnceItReachesTheThreshold() {
        var impression = onScreen()

        #expect(impression.windowFractionChanged(to: 0.4) == .none)
        #expect(impression.windowFractionChanged(to: 0.5) == .track)
        #expect(impression.windowFractionChanged(to: 1) == .none)
    }

    @Test func doesNotTrackBeforeAppearing() {
        var impression = ImpressionState(threshold: 0.5, minVisibleDuration: 0)

        #expect(impression.windowFractionChanged(to: 1) == .none)
        #expect(impression.appeared() == .track)
    }

    @Test func dippingBelowTheThresholdDoesNotCountAgain() {
        var impression = onScreen()
        _ = impression.windowFractionChanged(to: 1)

        #expect(impression.windowFractionChanged(to: 0.1) == .none)
        #expect(impression.windowFractionChanged(to: 1) == .none)
    }

    @Test func leavingTheWindowCompletelyCountsAgain() {
        var impression = onScreen()
        _ = impression.windowFractionChanged(to: 1)

        #expect(impression.windowFractionChanged(to: 0) == .none)
        #expect(impression.windowFractionChanged(to: 1) == .track)
    }

    @Test func disappearingCountsAgain() {
        var impression = onScreen()
        _ = impression.windowFractionChanged(to: 1)

        #expect(impression.disappeared() == .none)
        #expect(impression.appeared() == .track)
    }

    @Test func aZeroThresholdTracksAnyVisiblePart() {
        var impression = onScreen(threshold: 0)

        #expect(impression.windowFractionChanged(to: 0) == .none)
        #expect(impression.windowFractionChanged(to: 0.01) == .track)
    }

    @Test func waitsForTheMinimumDuration() {
        var impression = onScreen(minVisibleDuration: 1)

        #expect(impression.windowFractionChanged(to: 1) == .startWaiting)
        #expect(impression.windowFractionChanged(to: 0.9) == .none)
        #expect(impression.waited() == .track)
    }

    @Test func leavingWhileWaitingCancelsTheCount() {
        var impression = onScreen(minVisibleDuration: 1)
        _ = impression.windowFractionChanged(to: 1)

        #expect(impression.windowFractionChanged(to: 0.2) == .stopWaiting)
        #expect(impression.waited() == .none)
        #expect(impression.windowFractionChanged(to: 1) == .startWaiting)
    }

    @Test func disappearingWhileWaitingCancelsTheCount() {
        var impression = onScreen(minVisibleDuration: 1)
        _ = impression.windowFractionChanged(to: 1)

        #expect(impression.disappeared() == .stopWaiting)
        #expect(impression.waited() == .none)
    }

    @Test func aNewEventCountsAgain() {
        var impression = onScreen()
        _ = impression.windowFractionChanged(to: 1)

        #expect(impression.eventChanged() == .track)
    }

    @Test func aNewEventRestartsTheWait() {
        var impression = onScreen(minVisibleDuration: 1)
        _ = impression.windowFractionChanged(to: 1)

        #expect(impression.eventChanged() == .startWaiting)
    }

    @Test func aNewEventWhileHiddenStopsTheWait() {
        var impression = onScreen(minVisibleDuration: 1)
        _ = impression.windowFractionChanged(to: 1)
        _ = impression.windowFractionChanged(to: 0.2)

        #expect(impression.eventChanged() == .none)
    }

    @Test func aScrollViewCuttingItOffBelowTheThresholdHoldsTheCount() {
        var impression = onScreen()
        _ = impression.scrollVisibilityChanged(aboveThreshold: false)

        #expect(impression.windowFractionChanged(to: 1) == .none)
        #expect(impression.scrollVisibilityChanged(aboveThreshold: true) == .track)
    }

    @Test func leavingTheScrollViewCompletelyCountsAgain() {
        var impression = onScreen()
        _ = impression.windowFractionChanged(to: 1)

        _ = impression.scrollVisibilityChanged(aboveThreshold: false)
        #expect(impression.scrollPresenceChanged(partlyVisible: false) == .none)
        _ = impression.scrollPresenceChanged(partlyVisible: true)
        #expect(impression.scrollVisibilityChanged(aboveThreshold: true) == .track)
    }
}

@Suite struct VisibleFractionTests {
    private let window = CGRect(x: 0, y: 0, width: 100, height: 200)

    @Test func isOneInsideTheWindow() {
        #expect(visibleFraction(of: CGRect(x: 10, y: 10, width: 50, height: 50), in: window) == 1)
    }

    @Test func isZeroOutsideTheWindow() {
        #expect(visibleFraction(of: CGRect(x: 0, y: 300, width: 50, height: 50), in: window) == 0)
    }

    @Test func isThePartInsideTheWindow() {
        let halfBelow = CGRect(x: 0, y: 150, width: 100, height: 100)

        #expect(visibleFraction(of: halfBelow, in: window) == 0.5)
    }

    @Test func isZeroForAnEmptyFrame() {
        #expect(visibleFraction(of: CGRect(x: 10, y: 10, width: 0, height: 50), in: window) == 0)
    }
}
