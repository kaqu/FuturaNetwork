import Foundation

public protocol NetworkingProtocol {
    static func makeSession() -> NetworkSession
}

public final class Networking : NetworkingProtocol {
    
    public static func makeSession() -> NetworkSession {
        return NetworkSession() // TODO: to complete
    }
}
