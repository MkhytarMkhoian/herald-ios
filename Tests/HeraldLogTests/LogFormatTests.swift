import HeraldCore
import HeraldLog
import Testing

@Suite struct Format {
    let printed = Printed()

    @Test func anEventPrintsWithItsParametersAsOneRecord() {
        let event = TestEvent(
            name: "checkout_started",
            parameters: [
                "plan": .string("pro"), "seats": .int(3), "price": .double(9.99),
                "trial": .bool(false),
            ])

        GenericLogEventTracker(event: event, logger: printed.logger).track()

        #expect(
            printed.lines == [
                """
                [herald] event   checkout_started
                    ├─ plan  = pro
                    ├─ price = 9.99
                    ├─ seats = 3
                    └─ trial = false
                """
            ])
    }

    @Test func keysAreSortedSoTheSameEventAlwaysPrintsTheSameWay() {
        let event = TestEvent(name: "e", parameters: ["zulu": .string("z"), "alpha": .string("a")])

        GenericLogEventTracker(event: event, logger: printed.logger).track()

        #expect(printed.lines == ["[herald] event   e\n    ├─ alpha = a\n    └─ zulu  = z"])
    }

    @Test func aSingleParameterIsClosedNotBranched() {
        let event = TestEvent(name: "e", parameters: ["only": .int(1)])

        GenericLogEventTracker(event: event, logger: printed.logger).track()

        #expect(printed.lines == ["[herald] event   e\n    └─ only = 1"])
    }

    @Test func aScreenViewPrintsItsNameWithItsParameters() {
        let screen = TestScreenView(name: "checkout", parameters: ["source": .string("cart")])

        ScreenViewLogEventTracker(event: screen, logger: printed.logger).track()

        #expect(printed.lines == ["[herald] screen  checkout\n    └─ source = cart"])
    }

    @Test func aPropertyPrintsAsNameEqualsValue() {
        let property = TestProperty(name: "seats", value: .int(2))

        GenericLogPropertySetter(property: property, logger: printed.logger).set()

        #expect(printed.lines == ["[herald] prop    seats = 2"])
    }

    @Test func kindsArePaddedSoHeadlinesLineUp() {
        let service = LogAnalyticsService(logger: printed.logger)

        GenericLogEventTracker(event: TestEvent(name: "x"), logger: printed.logger).track()
        ScreenViewLogEventTracker(event: TestScreenView(name: "x"), logger: printed.logger).track()
        GenericLogPropertySetter(
            property: TestProperty(name: "x", value: .int(1)), logger: printed.logger
        ).set()
        service.identify(Identity(userId: "x"))
        service.setEnabled(true)

        // "[herald] " and a 7-wide kind with a space after it: every headline starts at column 17.
        let headlines = printed.lines.map { line in String(line.dropFirst(17)) }
        #expect(headlines == ["x", "x", "x = 1", "x", "true"])
    }
}
