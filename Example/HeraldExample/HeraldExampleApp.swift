import HeraldCore
import HeraldSwiftUI
import SwiftUI

@main
struct HeraldExampleApp: App {
    @StateObject private var timeline: TimelineAnalytics
    @State private var dark = false
    private let herald: Herald

    init() {
        let timeline = TimelineAnalytics()
        let herald = makeHerald(timeline: timeline)

        // Start the vendors, then re-apply the stored consent: some vendors forget it between
        // launches. This app stores nothing, so it starts without consent.
        herald.start()
        herald.setEnabled(false)

        _timeline = StateObject(wrappedValue: timeline)
        self.herald = herald
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                // Each screen gets only the protocols it needs; Herald implements them all.
                HomeScreen(timeline: timeline, herald: herald, dark: $dark)
            }
            .eventTracker(herald)  // for HeraldSwiftUI's screen views, impressions and taps
            .preferredColorScheme(dark ? .dark : .light)
        }
    }
}
