import SwiftUI
import Testing

@testable import HeraldSwiftUI

@Suite struct ScreenStateTests {
    @Test func appearingMakesItVisible() {
        var screen = ScreenState()

        #expect(screen.appeared(inBackground: false) == .visible)
    }

    @Test func disappearingHidesIt() {
        var screen = ScreenState()
        _ = screen.appeared(inBackground: false)

        #expect(screen.disappeared() == .hidden)
    }

    @Test func comingBackMakesItVisibleAgain() {
        var screen = ScreenState()
        _ = screen.appeared(inBackground: false)
        _ = screen.disappeared()

        #expect(screen.appeared(inBackground: false) == .visible)
    }

    @Test func aSecondAppearWithoutDisappearingDoesNotCount() {
        var screen = ScreenState()
        _ = screen.appeared(inBackground: false)

        #expect(screen.appeared(inBackground: false) == nil)
    }

    @Test func disappearingWithoutAppearingDoesNotCount() {
        var screen = ScreenState()

        #expect(screen.disappeared() == nil)
    }

    @Test func goingToTheBackgroundHidesItAndComingBackShowsIt() {
        var screen = ScreenState()
        _ = screen.appeared(inBackground: false)

        #expect(screen.phaseChanged(to: .inactive) == nil)
        #expect(screen.phaseChanged(to: .background) == .hidden)
        #expect(screen.phaseChanged(to: .inactive) == nil)
        #expect(screen.phaseChanged(to: .active) == .visible)
    }

    @Test func losingFocusOnlyDoesNotCount() {
        var screen = ScreenState()
        _ = screen.appeared(inBackground: false)

        #expect(screen.phaseChanged(to: .inactive) == nil)
        #expect(screen.phaseChanged(to: .active) == nil)
    }

    @Test func aScreenUnderAnotherOneIgnoresTheBackground() {
        var screen = ScreenState()
        _ = screen.appeared(inBackground: false)
        _ = screen.disappeared()

        #expect(screen.phaseChanged(to: .background) == nil)
        #expect(screen.phaseChanged(to: .active) == nil)
    }

    @Test func appearingInTheBackgroundCountsWhenTheAppComesBack() {
        var screen = ScreenState()

        #expect(screen.appeared(inBackground: true) == nil)
        #expect(screen.phaseChanged(to: .active) == .visible)
    }

    @Test func closingInTheBackgroundDoesNotCountAgain() {
        var screen = ScreenState()
        _ = screen.appeared(inBackground: false)
        _ = screen.phaseChanged(to: .background)

        #expect(screen.disappeared() == nil)
    }
}
