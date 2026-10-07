import HeraldCore
import HeraldSwiftUI
import SwiftUI

/// Products, and below them every call Herald made, newest first.
struct HomeScreen: View {
    static let products = ["day_pass", "week_pass", "month_pass"]

    @ObservedObject var timeline: TimelineAnalytics
    let herald: Herald
    @Binding var dark: Bool

    var body: some View {
        List {
            Section {
                ForEach(Self.products, id: \.self) { productId in
                    NavigationLink(productId) {
                        ProductScreen(productId: productId, analytics: herald, properties: herald)
                    }
                }
            }
            Section("What Herald sent") {
                ForEach(Array(timeline.lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(.footnote, design: .monospaced))
                        .accessibilityIdentifier("timeline-line")
                }
            }
        }
        .navigationTitle("Herald example")
        .toolbar {
            NavigationLink {
                SettingsScreen(
                    analytics: herald, consent: herald, identity: herald, properties: herald,
                    dark: $dark)
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }
        // From HeraldSwiftUI: each time Home becomes visible, also when the user comes back to it.
        .trackScreenView(HomeViewed())
    }
}
