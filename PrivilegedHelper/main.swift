import Foundation

// Privileged helper entry point.
// Runs as root via SMAppService.daemon. NSXPCListener accepts a connection only
// from the main app, identified by code-signing requirement (SMAuthorizedClients
// in Info.plist) AND an in-process audit token check.

let delegate = HelperListenerDelegate()
let listener = NSXPCListener(machServiceName: helperMachServiceName)
listener.delegate = delegate
listener.resume()

NSLog("[mac-cleaner-pro.helper] listening on \(helperMachServiceName)")

RunLoop.current.run()
