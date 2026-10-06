/// One call to the log for one event. A factory builds it.
public protocol LogEventTracker {
    func track() throws
}
