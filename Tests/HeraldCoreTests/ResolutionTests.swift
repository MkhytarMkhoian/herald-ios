import HeraldCore
import Testing

@Test func claimedGivesItsHandlers() throws {
    #expect(try Resolution.claimed(["a", "b"]).handlers() == ["a", "b"])
}

@Test func claimedWithNoHandlersThrowsAndPointsToDropped() {
    #expect {
        try Resolution<String>.claimed([]).handlers()
    } throws: { error in
        "\(error)".contains(".dropped")
    }
}

@Test func droppedAndDeclinedGiveNoHandlers() throws {
    #expect(try Resolution<String>.dropped.handlers().isEmpty)
    #expect(try Resolution<String>.declined.handlers().isEmpty)
}

@Test func droppedAndDeclinedAreNotEqual() {
    #expect(Resolution<String>.dropped != .declined)
}

@Suite struct FirstOf {
    @Test func returnsTheFirstAnswerThatIsNotADecline() throws {
        let answers: [Resolution<String>] = [.declined, .claimed(["first"]), .claimed(["second"])]

        let answer = try Resolution.firstOf(answers) { answer in answer }

        #expect(answer == .claimed(["first"]))
    }

    @Test func countsDroppedAsAnAnswer() throws {
        let answers: [Resolution<String>] = [.declined, .dropped, .claimed(["late"])]

        #expect(try Resolution.firstOf(answers) { answer in answer } == .dropped)
    }

    @Test func declinesWhenAllDeclineOrThereAreNone() throws {
        let none: [Resolution<String>] = []

        #expect(
            try Resolution.firstOf([Resolution<String>.declined]) { answer in answer } == .declined)
        #expect(try Resolution.firstOf(none) { answer in answer } == .declined)
    }

    @Test func stopsAskingOnceOneHasAnswered() throws {
        var asked: [Int] = []

        _ = try Resolution<String>.firstOf([0, 1, 2]) { number in
            asked.append(number)
            return number == 1 ? .claimed(["one"]) : .declined
        }

        #expect(asked == [0, 1])
    }

    @Test func passesOnWhatAFactoryThrows() {
        #expect(throws: TestError(message: "unmapped")) {
            try Resolution<String>.firstOf([0]) { _ in throw TestError(message: "unmapped") }
        }
    }
}
