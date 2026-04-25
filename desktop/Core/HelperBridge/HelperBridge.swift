import Foundation

/// Async/await wrapper around `NSXPCConnection` to the privileged helper.
///
/// Owns a single lazily-created connection and reuses it across calls. Failures
/// fall into two buckets:
/// 1. Helper-reported errors (path not allowlisted, IO failure) → propagated as `HelperError`.
/// 2. Connection-level errors (helper not installed, crashed, peer rejected) → surfaced as
///    `HelperError.connectionInvalid` so callers don't need to know about NSXPC.
public actor HelperBridge {

    public static let shared = HelperBridge()

    private var connection: NSXPCConnection?

    public init() {}

    // MARK: - Public API

    public func version() async throws -> String {
        try await call { proxy, resume in
            proxy.version { value in resume(.success(value)) }
        }
    }

    @discardableResult
    public func trashSystemPaths(_ paths: [String]) async throws -> UInt64 {
        try await call { proxy, resume in
            proxy.trashSystemPaths(paths) { reclaimed, error in
                if let error { resume(.failure(error)) } else { resume(.success(reclaimed)) }
            }
        }
    }

    public func sizesForSystemPaths(_ paths: [String]) async throws -> [String: UInt64] {
        try await call { proxy, resume in
            proxy.sizesForSystemPaths(paths) { sizes, error in
                if let error { resume(.failure(error)) } else { resume(.success(sizes)) }
            }
        }
    }

    /// Tear down the cached connection; the next call rebuilds it. Useful after
    /// (un)registering the helper via SMAppService so we don't reuse a dead handle.
    public func invalidate() {
        connection?.invalidate()
        connection = nil
    }

    // MARK: - Internals

    private func ensureConnection() -> NSXPCConnection {
        if let existing = connection { return existing }
        let conn = NSXPCConnection(machServiceName: helperMachServiceName, options: .privileged)
        conn.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        conn.invalidationHandler = { [weak self] in
            Task { await self?.handleInvalidation() }
        }
        conn.interruptionHandler = { [weak self] in
            Task { await self?.handleInvalidation() }
        }
        conn.resume()
        connection = conn
        return conn
    }

    private func handleInvalidation() {
        connection = nil
    }

    /// Bridges a reply-block helper call into async/await. The body receives the
    /// remote proxy and a `resume` closure it must call exactly once. If XPC
    /// delivery fails before the reply arrives, the continuation is resumed with
    /// `HelperError.connectionInvalid`. A latch ensures at-most-once resumption.
    private func call<T>(
        _ body: @escaping (HelperProtocol, @escaping (Result<T, Error>) -> Void) -> Void
    ) async throws -> T {
        let conn = ensureConnection()
        return try await withCheckedThrowingContinuation { continuation in
            let latch = ResumeLatch()
            let resume: (Result<T, Error>) -> Void = { result in
                guard latch.tryConsume() else { return }
                continuation.resume(with: result)
            }
            let proxy = conn.remoteObjectProxyWithErrorHandler { _ in
                resume(.failure(HelperError.connectionInvalid))
            } as? HelperProtocol
            guard let proxy else {
                resume(.failure(HelperError.connectionInvalid))
                return
            }
            body(proxy, resume)
        }
    }
}

/// Single-use latch — the reply block and the XPC error handler race; only one wins.
private final class ResumeLatch: @unchecked Sendable {
    private let lock = NSLock()
    private var consumed = false
    func tryConsume() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if consumed { return false }
        consumed = true
        return true
    }
}
