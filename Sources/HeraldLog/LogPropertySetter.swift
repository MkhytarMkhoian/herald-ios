/// One call to the log for one property. A factory builds it.
public protocol LogPropertySetter {
    func set() throws
}
