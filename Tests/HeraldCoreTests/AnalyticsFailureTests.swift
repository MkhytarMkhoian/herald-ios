import HeraldCore
import Testing

@Test func operationsPrintTheirKindAndName() {
    #expect(
        "\(AnalyticsOperation.track(eventName: "checkout_started"))" == "Track(checkout_started)")
    #expect("\(AnalyticsOperation.setProperty(propertyName: "plan"))" == "SetProperty(plan)")
    #expect("\(AnalyticsOperation.setEnabled(false))" == "SetEnabled(false)")
    #expect("\(AnalyticsOperation.identify)" == "Identify")
}

@Test func operationsAreEqualByKindAndName() {
    #expect(AnalyticsOperation.track(eventName: "a") == .track(eventName: "a"))
    #expect(AnalyticsOperation.track(eventName: "a") != .track(eventName: "b"))
    #expect(AnalyticsOperation.track(eventName: "plan") != .setProperty(propertyName: "plan"))
    #expect(AnalyticsOperation.start != .flush)
}

@Test func aFailureReadsAsOneLineWithTheVendorTheCallAndTheError() {
    struct Down: Error, CustomStringConvertible {
        var description: String { "down" }
    }
    let failure = AnalyticsFailure(
        provider: "analytics", operation: .track(eventName: "checkout_started"), error: Down())

    #expect("\(failure)" == "analytics failed on Track(checkout_started): down")
}

@Test func unhandledErrorsNameTheEventOrPropertyAndItsType() {
    let event = UnhandledEventError(event: TestEvent(name: "checkout_started"))
    let property = UnhandledPropertyError(
        property: TestProperty(name: "plan", value: .string("pro")))

    #expect("\(event)".contains("'checkout_started' (TestEvent)"))
    #expect("\(property)".contains("'plan' (TestProperty)"))
}
