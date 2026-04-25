import Foundation

final class HelperListenerDelegate: NSObject, NSXPCListenerDelegate {

    func listener(_ listener: NSXPCListener,
                  shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {

        // Defense in depth: SMAuthorizedClients in Info.plist is the primary gate,
        // but we also validate the connecting peer's code-sign requirement here.
        guard CodeSignValidator.connectionMatchesAppRequirement(newConnection) else {
            NSLog("[helper] rejected connection: code-sign requirement not satisfied")
            return false
        }

        newConnection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        newConnection.exportedObject = HelperService()
        newConnection.invalidationHandler = { NSLog("[helper] connection invalidated") }
        newConnection.interruptionHandler = { NSLog("[helper] connection interrupted") }
        newConnection.resume()
        return true
    }
}
