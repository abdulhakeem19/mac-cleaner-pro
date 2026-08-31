import Foundation
import Dispatch

/// Wraps `DISPATCH_SOURCE_TYPE_MEMORYPRESSURE` so the rest of the app can listen
/// to kernel-emitted pressure transitions without poking dispatch APIs directly.
///
/// Kernel-driven (not heuristic): the kernel decides when to fire `.warning` /
/// `.critical`. We just translate the bitmask to `MemoryPressureLevel`.
public final class PressureMonitor: @unchecked Sendable {

    public typealias Handler = @Sendable (MemoryPressureLevel) -> Void

    private let handler: Handler
    private var source: DispatchSourceMemoryPressure?
    private let queue: DispatchQueue

    public init(queue: DispatchQueue = DispatchQueue.global(qos: .utility),
                handler: @escaping Handler) {
        self.queue = queue
        self.handler = handler
    }

    public func start() {
        guard source == nil else { return }
        let s = DispatchSource.makeMemoryPressureSource(
            eventMask: [.normal, .warning, .critical],
            queue: queue
        )
        s.setEventHandler { [weak self] in
            guard let self, let src = self.source else { return }
            let evt = src.data
            let level: MemoryPressureLevel
            if evt.contains(.critical)     { level = .critical }
            else if evt.contains(.warning) { level = .warning  }
            else                           { level = .normal   }
            self.handler(level)
        }
        s.resume()
        source = s
    }

    public func stop() {
        source?.cancel()
        source = nil
    }

    deinit { source?.cancel() }
}
