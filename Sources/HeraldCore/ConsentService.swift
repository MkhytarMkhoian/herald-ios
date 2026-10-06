/// Turns a vendor's data collection on or off.
///
/// It can't stop what a vendor collects before the first call. Some vendors need their own setting
/// to start with collection off; each vendor module says what it needs.
public protocol ConsentService: Sendable {
    func setEnabled(_ enabled: Bool)
}
