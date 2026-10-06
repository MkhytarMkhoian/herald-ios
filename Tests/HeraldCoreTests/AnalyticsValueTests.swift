import HeraldCore
import Testing

@Test func asStringIsTheValueAsText() {
    #expect(AnalyticsValue.string("pro").asString == "pro")
    #expect(AnalyticsValue.int(3).asString == "3")
    #expect(AnalyticsValue.double(9.99).asString == "9.99")
    #expect(AnalyticsValue.double(3).asString == "3.0")
    #expect(AnalyticsValue.bool(true).asString == "true")
}

@Test func valuesAreEqualByTypeAndValueSoThreeIsNotTheTextThree() {
    #expect(AnalyticsValue.int(3) == .int(3))
    #expect(AnalyticsValue.int(3) != .string("3"))
    #expect(AnalyticsValue.double(3) != .int(3))
    #expect(AnalyticsValue.bool(true) != .string("true"))
}

@Test func anEventWithoutParametersHasNone() {
    struct Bare: Event {
        var name: String { "bare" }
    }

    #expect(Bare().parameters.isEmpty)
}
