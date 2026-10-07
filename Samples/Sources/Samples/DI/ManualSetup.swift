import HeraldCore

// --8<-- [start:manual]
final class AppGraph {
    private let herald: Herald

    init(herald: Herald) {
        self.herald = herald
    }

    // CheckoutViewModel asks for an EventTrackerService; Herald is one, so it's passed as that.
    func checkoutViewModel() -> CheckoutViewModel {
        CheckoutViewModel(analytics: herald)
    }
}
// --8<-- [end:manual]
