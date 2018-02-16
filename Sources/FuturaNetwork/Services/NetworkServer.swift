import Foundation
import FuturaAsync

public protocol NetworkServer {
    
    var session: NetworkSession { get }
    
    var url: URL { get }
    
    static var requestTimeout: ConfigurationParameter<TimeInterval> { get }
    static var requestHeaders: ConfigurationParameter<HTTPHeaders> { get }
    static var allowCookies: ConfigurationParameter<Bool> { get }
    static var allowCellularNetwork: ConfigurationParameter<Bool> { get }
    static var cachePolicy: ConfigurationParameter<CachePolicy> { get }
}

public extension NetworkServer {
    
    static var requestTimeout: ConfigurationParameter<TimeInterval> { return .inherit }
    static var requestHeaders: ConfigurationParameter<HTTPHeaders> { return .inherit }
    static var allowCookies: ConfigurationParameter<Bool> { return .inherit }
    static var allowCellularNetwork: ConfigurationParameter<Bool> { return .inherit }
    static var cachePolicy: ConfigurationParameter<CachePolicy> { return .inherit }
}

public extension NetworkServer {
    
    func call<Endpoint:NetworkEndpoint>(endpoint: Endpoint.Type, with request: Endpoint.Request) -> Future<Endpoint.Response> {
        do {
            return try self.make(endpointRequest: endpoint.endpointRequest(from: request))
//            return try session.do(request: httpRequest(for: endpoint, with: request)).valueMap { (httpResponse) -> (Endpoint.Response) in
//                try endpoint.response(from: httpResponse)
//            }
        } catch {
            return Future<Endpoint.Response>(error: error)
        }
    }
    
    func make<Endpoint>(endpointRequest: EndpointRequest<Endpoint>) -> Future<Endpoint.Response> {
        do {
            return try session.do(request: httpRequest(for: endpointRequest)).valueMap { (httpResponse) -> (Endpoint.Response) in
                try endpointRequest.endpoint.response(from: httpResponse)
            }
        } catch {
            return Future<Endpoint.Response>(error: error)
        }
    }
}

internal extension NetworkServer {

    func httpRequest<Endpoint:NetworkEndpoint>(for endpoint: Endpoint.Type, with request: Endpoint.Request) throws -> HTTPRequest {
        return try httpRequest(for: endpoint.endpointRequest(from: request))
//        return HTTPRequest(
//            url: url.appendingPathComponent(endpointRequest.path),
//            urlQueryParameters: endpointRequest.urlQueryParameters ?? [:],
//            headers: endpoint.requestHeaders.resolve(with: type(of: self).requestHeaders.resolve(with: session.requestHeaders)),
//            task: endpointRequest.httpRequestTask,
//            timeout: endpoint.requestTimeout.resolve(with: type(of: self).requestTimeout.resolve(with: session.requestTimeout)),
//            allowCookies: endpoint.allowCookies.resolve(with: type(of: self).allowCookies.resolve(with: session.allowCookies)),
//            allowCellularNetwork: endpoint.allowCellularNetwork.resolve(with: type(of: self).allowCellularNetwork.resolve(with: session.allowCellularNetwork)),
//            cachePolicy: endpoint.cachePolicy.resolve(with: type(of: self).cachePolicy.resolve(with: session.cachePolicy))
//        )
    }
    
    func httpRequest<Endpoint>(for endpointRequest: EndpointRequest<Endpoint>) throws -> HTTPRequest {
        return HTTPRequest(
            url: url.appendingPathComponent(endpointRequest.path),
            urlQueryParameters: endpointRequest.urlQueryParameters ?? [:],
            headers: endpointRequest.endpoint.requestHeaders.resolve(with: type(of: self).requestHeaders.resolve(with: session.requestHeaders)),
            task: endpointRequest.httpRequestTask,
            timeout: endpointRequest.endpoint.requestTimeout.resolve(with: type(of: self).requestTimeout.resolve(with: session.requestTimeout)),
            allowCookies: endpointRequest.endpoint.allowCookies.resolve(with: type(of: self).allowCookies.resolve(with: session.allowCookies)),
            allowCellularNetwork: endpointRequest.endpoint.allowCellularNetwork.resolve(with: type(of: self).allowCellularNetwork.resolve(with: session.allowCellularNetwork)),
            cachePolicy: endpointRequest.endpoint.cachePolicy.resolve(with: type(of: self).cachePolicy.resolve(with: session.cachePolicy))
        )
    }
    
//    func request<Endpoint:NetworkEndpoint>(for endpoint: Endpoint.Type, with payload: Endpoint.RequestPayload) throws -> HTTPRequest {
//        let requestTask = try endpoint.requestTask(with: payload)
//        return HTTPRequest(
//            url: url.appendingPathComponent(endpoint.path), urlQueryParameters: [:],
//            headers: endpoint.requestHeaders.resolve(with: type(of: self).requestHeaders.resolve(with: session.requestHeaders)),
//            method: requestTask.httpMethod,
//            body: requestTask.httpBody,
//            timeout: endpoint.requestTimeout.resolve(with: type(of: self).requestTimeout.resolve(with: session.requestTimeout)),
//            allowCookies: endpoint.allowCookies.resolve(with: type(of: self).allowCookies.resolve(with: session.allowCookies)),
//            allowCellularNetwork: endpoint.allowCellularNetwork.resolve(with: type(of: self).allowCellularNetwork.resolve(with: session.allowCellularNetwork)),
//            cachePolicy: endpoint.cachePolicy.resolve(with: type(of: self).cachePolicy.resolve(with: session.cachePolicy))
//        )
//    }
}
