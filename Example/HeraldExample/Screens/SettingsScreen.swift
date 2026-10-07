import HeraldCore
import SwiftUI

/// Consent, sign-in and a preference: each control needs a different analytics protocol, and gets
/// only that one.
///
/// It tracks its own screen view with plain Herald, no HeraldSwiftUI: once each time it opens.
/// (Home and Product use `.trackScreenView`, which also counts coming back to them.)
@MainActor
final class SettingsModel: ObservableObject {
    @Published private(set) var consent = false
    @Published private(set) var signedIn = false
    private let consentService: any ConsentService
    private let identity: any IdentifiableUserService
    private let properties: any PropertyTrackerService

    init(
        analytics: any EventTrackerService, consent: any ConsentService,
        identity: any IdentifiableUserService, properties: any PropertyTrackerService
    ) {
        self.consentService = consent
        self.identity = identity
        self.properties = properties
        analytics.track(SettingsViewed())
    }

    func setConsent(_ enabled: Bool) {
        consent = enabled
        consentService.setEnabled(enabled)
    }

    func setSignedIn(_ signedIn: Bool) {
        self.signedIn = signedIn
        if signedIn {
            identity.identify(Identity(userId: "user-42"))
        } else {
            identity.reset()
        }
    }

    func themeChanged(dark: Bool) {
        properties.set(AppTheme(dark: dark))
    }
}

struct SettingsScreen: View {
    @StateObject private var model: SettingsModel
    @Binding var dark: Bool

    init(
        analytics: any EventTrackerService, consent: any ConsentService,
        identity: any IdentifiableUserService, properties: any PropertyTrackerService,
        dark: Binding<Bool>
    ) {
        _model = StateObject(
            wrappedValue: SettingsModel(
                analytics: analytics, consent: consent, identity: identity, properties: properties)
        )
        _dark = dark
    }

    var body: some View {
        Form {
            Toggle(
                "Share analytics",
                isOn: Binding(get: { model.consent }, set: { on in model.setConsent(on) }))
            Toggle(
                "Signed in as user-42",
                isOn: Binding(get: { model.signedIn }, set: { on in model.setSignedIn(on) }))
            Toggle(
                "Dark theme",
                isOn: Binding(
                    get: { dark },
                    set: { on in
                        dark = on
                        model.themeChanged(dark: on)
                    }))
        }
        .navigationTitle("Settings")
    }
}
