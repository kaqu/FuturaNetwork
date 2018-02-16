import Foundation

public enum NetworkError : Error {
    
    // MARK: request
    case invalidRequest
    
    // MARK: response
    case invalidResponse
    case unsupportedResponse(Any)
    
    // MARK: connection
    case requestTimeout
    case noConnection
    
    // MARK: other
    case unknownError(Error, info: String?)
}
