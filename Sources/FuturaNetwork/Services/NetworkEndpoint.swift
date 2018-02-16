//
//  NetworkEndpoint.swift
//  FuturaNetwork
//
//  Created by Kacper Kaliński on 29/12/2017.
//

import Foundation

public protocol NetworkEndpoint {
    associatedtype Request
    associatedtype Response
    
    static var path: String { get }
    static var requestTimeout: ConfigurationParameter<TimeInterval> { get }
    static var requestHeaders: ConfigurationParameter<HTTPHeaders> { get }
    static var allowCookies: ConfigurationParameter<Bool> { get }
    static var allowCellularNetwork: ConfigurationParameter<Bool> { get }
    static var cachePolicy: ConfigurationParameter<CachePolicy> { get }
    
    static func endpointRequest(from request: Request) throws -> EndpointRequest<Self>
    static func response(from httpResponse: HTTPResponse) throws -> Response
}

public extension NetworkEndpoint {
    
    static var requestTimeout: ConfigurationParameter<TimeInterval> { return .inherit }
    static var requestHeaders: ConfigurationParameter<HTTPHeaders> { return .inherit }
    static var allowCookies: ConfigurationParameter<Bool> { return .inherit }
    static var allowCellularNetwork: ConfigurationParameter<Bool> { return .inherit }
    static var cachePolicy: ConfigurationParameter<CachePolicy> { return .inherit }
}

internal extension NetworkEndpoint {

}

public struct EndpointRequest<Endpoint: NetworkEndpoint> {
    
    public let endpoint: Endpoint.Type
    public var path: String
    public var urlQueryParameters: HTTPRequest.URLQueryParameters?
    public var httpRequestTask: HTTPRequest.Task
    
    public init(_ endpoint: Endpoint.Type, path: String, urlQueryParameters: HTTPRequest.URLQueryParameters?, httpRequestTask: HTTPRequest.Task) {
        self.endpoint = endpoint
        self.path = path
        self.urlQueryParameters = urlQueryParameters
        self.httpRequestTask = httpRequestTask
    }
}
