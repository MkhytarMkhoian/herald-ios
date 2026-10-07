import CoreGraphics
import Foundation

/// Decides when an impression counts, from what its view reports: appearing and disappearing, how
/// much of it is inside the window, and on iOS 18 and newer how much is inside its scroll view.
///
/// It doesn't track or wait itself: each call returns what to do, so the rules can be tested
/// without a screen.
struct ImpressionState {
    enum Action: Equatable {
        case none
        case track
        case startWaiting
        case stopWaiting
    }

    var threshold: Double
    var minVisibleDuration: TimeInterval

    private var isOnScreen = false
    private var windowFraction = 0.0
    // Without a scroll view, or before iOS 18, nothing reports these: nothing clips the view.
    private var isAboveThresholdInScrollView = true
    private var isPartlyInScrollView = true
    private var tracked = false
    private var waiting = false

    init(threshold: Double, minVisibleDuration: TimeInterval) {
        self.threshold = threshold
        self.minVisibleDuration = minVisibleDuration
    }

    mutating func appeared() -> Action {
        isOnScreen = true
        return evaluate()
    }

    mutating func disappeared() -> Action {
        isOnScreen = false
        return evaluate()
    }

    mutating func windowFractionChanged(to fraction: Double) -> Action {
        windowFraction = fraction
        return evaluate()
    }

    mutating func scrollVisibilityChanged(aboveThreshold: Bool) -> Action {
        isAboveThresholdInScrollView = aboveThreshold
        return evaluate()
    }

    mutating func scrollPresenceChanged(partlyVisible: Bool) -> Action {
        isPartlyInScrollView = partlyVisible
        return evaluate()
    }

    /// A different event: it counts again, from the start.
    mutating func eventChanged() -> Action {
        let wasWaiting = waiting
        restart()
        let next = evaluate()
        if wasWaiting && next == .none {
            return .stopWaiting
        }
        return next
    }

    /// The wait for ``minVisibleDuration`` ended while still visible.
    mutating func waited() -> Action {
        if !waiting {
            return .none
        }
        waiting = false
        tracked = true
        return .track
    }

    private mutating func evaluate() -> Action {
        let gone = !isOnScreen || windowFraction == 0 || !isPartlyInScrollView
        if gone {
            let wasWaiting = waiting
            restart()  // the next appearance counts again
            return wasWaiting ? .stopWaiting : .none
        }
        if tracked {
            return .none
        }
        let visible = windowFraction >= threshold && isAboveThresholdInScrollView
        if !visible {
            if waiting {
                waiting = false
                return .stopWaiting
            }
            return .none
        }
        if minVisibleDuration <= 0 {
            tracked = true
            return .track
        }
        if waiting {
            return .none
        }
        waiting = true
        return .startWaiting
    }

    private mutating func restart() {
        tracked = false
        waiting = false
    }
}

/// How much of `frame` is inside `window`, from 0 to 1. An empty frame is not visible.
func visibleFraction(of frame: CGRect, in window: CGRect) -> Double {
    let area = frame.width * frame.height
    if area <= 0 {
        return 0
    }
    let visible = frame.intersection(window)
    if visible.isNull {
        return 0
    }
    return Double(visible.width * visible.height / area)
}
