import Foundation
import Testing

@testable import HeraldCore

private struct Mapped {}

private struct Generic: FallbackFactory {}

private struct RequireMapped: FallbackFactory {}

@Test func aChainWithTheFallbackLastIsAccepted() {
    #expect(fallbackOrderProblem([Mapped(), Mapped(), Generic()]) == nil)
}

@Test func aChainWithoutAFallbackIsAccepted() {
    #expect(fallbackOrderProblem([Mapped(), Mapped()]) == nil)
}

@Test func aFallbackInTheMiddleIsRefusedWithItsNameAndPosition() throws {
    let problem = try #require(fallbackOrderProblem([Mapped(), Generic(), Mapped()]))

    #expect(problem.contains("Generic answers for everything"))
    #expect(problem.contains("factory 2 of 3"))
}

@Test func aFallbackFirstInALongerChainIsRefused() {
    #expect(fallbackOrderProblem([Generic(), Mapped()]) != nil)
}

@Test func twoFallbacksAreRefused() throws {
    let problem = try #require(fallbackOrderProblem([Mapped(), Generic(), RequireMapped()]))

    #expect(problem.contains("this one has 2: Generic (factory 2), RequireMapped (factory 3)"))
}

#if os(macOS)
    @Test func aWrongChainStopsTheApp() async throws {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent])
        {
            requireFallbackLast([Generic(), Mapped()])
        }
        let message = String(decoding: try #require(result).standardErrorContent, as: UTF8.self)
        #expect(message.contains("move it to the end"))
    }
#endif
