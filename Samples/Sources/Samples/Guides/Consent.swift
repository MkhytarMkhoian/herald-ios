import HeraldCore

/// However your app stores the user's answer.
protocol AnalyticsConsentRepository: Sendable {
    func isEnabled() -> Bool
    func setEnabled(_ enabled: Bool)
}

// --8<-- [start:record]
final class PrivacySettingsController {
    private let consentRepository: any AnalyticsConsentRepository
    private let consent: any ConsentService

    init(consentRepository: any AnalyticsConsentRepository, consent: any ConsentService) {
        self.consentRepository = consentRepository
        self.consent = consent
    }

    func onAnalyticsConsentChanged(enabled: Bool) {
        consentRepository.setEnabled(enabled)  // save the answer first
        consent.setEnabled(enabled)  // then apply it to every vendor
    }
}
// --8<-- [end:record]

func restoreConsent(
    analytics: any AnalyticsLifecycleService,
    consent: any ConsentService,
    consentRepository: any AnalyticsConsentRepository
) {
    // --8<-- [start:restore]
    analytics.start()  // some vendors start quiet here
    consent.setEnabled(consentRepository.isEnabled())  // so re-apply it, every launch
    // --8<-- [end:restore]
}
