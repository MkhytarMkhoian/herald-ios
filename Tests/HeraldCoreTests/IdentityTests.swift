import HeraldCore
import Testing

@Test func identitiesAreEqualByUserId() {
    #expect(Identity(userId: "u") == Identity(userId: "u"))
    #expect(Identity(userId: "u") != Identity(userId: "v"))
}

@Test func anIdentityHidesItsUserIdWhenPrinted() {
    let identity = Identity(userId: "user-42")

    #expect(!"\(identity)".contains("user-42"))
    #expect(!String(reflecting: identity).contains("user-42"))
    #expect(identity.userId == "user-42")
}
