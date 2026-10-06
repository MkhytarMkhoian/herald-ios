import HeraldCore
import HeraldLog
import Testing

private let event = TestEvent(name: "an_event")
private let screenView = TestScreenView(name: "checkout")
private let property = TestProperty(name: "plan", value: .string("pro"))

@Suite struct Factories {
    let printed = Printed()

    @Test func theScreenViewFactoryClaimsScreenViewsAndDeclinesTheRest() throws {
        let factory = ScreenViewLogEventTrackerFactory(logger: printed.logger)

        #expect(try factory.create(screenView).handlers().first is ScreenViewLogEventTracker)
        #expect(try factory.create(event).handlers().isEmpty)
    }

    @Test func theGenericFactoriesClaimEverything() throws {
        let events = GenericLogEventTrackerFactory(logger: printed.logger)
        let properties = GenericLogPropertySetterFactory(logger: printed.logger)

        #expect(try events.create(screenView).handlers().first is GenericLogEventTracker)
        #expect(try properties.create(property).handlers().first is GenericLogPropertySetter)
    }

    @Test func theRequireMappedFactoriesFailForAnythingThatReachesThem() {
        #expect(throws: UnhandledEventError.self) {
            try RequireMappedLogEventTrackerFactory().create(event)
        }
        #expect(throws: UnhandledPropertyError.self) {
            try RequireMappedLogPropertySetterFactory().create(property)
        }
    }

    @Test func aChainTakesTheFirstFactoryThatDoesNotDecline() throws {
        let chain = CompositeLogEventTrackerFactory([
            ScreenViewLogEventTrackerFactory(logger: printed.logger),
            GenericLogEventTrackerFactory(logger: printed.logger),
        ])

        #expect(try chain.create(screenView).handlers().first is ScreenViewLogEventTracker)
        #expect(try chain.create(event).handlers().first is GenericLogEventTracker)
    }

    @Test func aCustomFactoryPlacedFirstTakesItsEventFromTheGenericOne() throws {
        let chain = CompositeLogEventTrackerFactory([
            ClaimingLogEventTrackerFactory(
                name: "an_event", steps: [.print("custom")], logger: printed.logger),
            GenericLogEventTrackerFactory(logger: printed.logger),
        ])

        for tracker in try chain.create(event).handlers() {
            try tracker.track()
        }

        #expect(printed.lines == ["custom"])
        #expect(try chain.create(screenView).handlers().first is GenericLogEventTracker)
    }

    #if os(macOS)
        @Test func aChainWithItsFallbackAnywhereButLastIsRefused() async throws {
            let result = await #expect(
                processExitsWith: .failure, observing: [\.standardErrorContent]
            ) {
                _ = CompositeLogEventTrackerFactory([
                    GenericLogEventTrackerFactory(logger: { _ in }),
                    ScreenViewLogEventTrackerFactory(logger: { _ in }),
                ])
            }
            let message = String(
                decoding: try #require(result).standardErrorContent, as: UTF8.self)
            #expect(message.contains("GenericLogEventTrackerFactory answers for everything"))
        }
    #endif
}
