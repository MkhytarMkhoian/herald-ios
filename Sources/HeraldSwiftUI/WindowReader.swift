import SwiftUI

/// Finds the window a view is in, so an impression can tell how much of the view is inside it.
///
/// SwiftUI gives a view's frame in window coordinates but not the window's size, so an empty
/// UIKit (or AppKit) view placed behind it asks its window.
@MainActor
final class WindowReader {
    fileprivate weak var view: PlatformView?
    /// The view's last frame, kept for when it gets into a window.
    var lastFrame: CGRect?
    /// Called once the view is in a window, since the frame read before that couldn't be used.
    var onAttach: (() -> Void)?

    /// The window's bounds, or nil before the view is in one.
    var bounds: CGRect? {
        #if canImport(UIKit)
            return view?.window?.bounds
        #else
            return view?.window?.contentView?.bounds
        #endif
    }
}

#if canImport(UIKit)
    typealias PlatformView = UIView

    struct WindowReaderView: UIViewRepresentable {
        let reader: WindowReader

        func makeUIView(context: Context) -> ProbeView {
            let view = ProbeView()
            view.reader = reader
            reader.view = view
            return view
        }

        func updateUIView(_ view: ProbeView, context: Context) {}
    }

    final class ProbeView: UIView {
        weak var reader: WindowReader?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil {
                reader?.onAttach?()
            }
        }
    }
#else
    typealias PlatformView = NSView

    struct WindowReaderView: NSViewRepresentable {
        let reader: WindowReader

        func makeNSView(context: Context) -> ProbeView {
            let view = ProbeView()
            view.reader = reader
            reader.view = view
            return view
        }

        func updateNSView(_ view: ProbeView, context: Context) {}
    }

    final class ProbeView: NSView {
        weak var reader: WindowReader?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil {
                reader?.onAttach?()
            }
        }
    }
#endif
