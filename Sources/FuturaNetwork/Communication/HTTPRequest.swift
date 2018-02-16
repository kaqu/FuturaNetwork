import Foundation
import FuturaAsync

public struct HTTPRequest {
    
    public var url: URL
    public var queryParameters: URLQueryParameters
    public var headers: HTTPHeaders
    public var method: Method
    public var body: HTTPBody
    public var timeout: TimeInterval
    public var allowCookies: Bool
    public var allowCellularNetwork: Bool
    public var cachePolicy: CachePolicy
    
    public init(url: URL, urlQueryParameters: URLQueryParameters = [:], headers: HTTPHeaders = [:], task: Task, timeout: TimeInterval = 60, allowCookies: Bool = true, allowCellularNetwork: Bool = true, cachePolicy: CachePolicy = .ignore) {
        self.url = url
        self.queryParameters = urlQueryParameters
        self.headers = headers
        self.method = task.httpMethod
        self.body = task.httpBody
        self.timeout = timeout
        self.allowCookies = allowCookies
        self.allowCellularNetwork = allowCellularNetwork
        self.cachePolicy = cachePolicy
    }
}

internal extension HTTPRequest {
    
    var urlRequest: URLRequest {
        var request: URLRequest
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !queryParameters.isEmpty {
//            urlComponents.percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + HTTPRequest.query(for: urlQueryParameters)
            urlComponents.queryItems = queryParameters.urlQueryItems
            request = URLRequest(url: urlComponents.url ?? url, timeoutInterval: timeout)
        } else {
            request = URLRequest(url: url, timeoutInterval: timeout)
        }
        
        request.allHTTPHeaderFields = headers.merging(body.headers, uniquingKeysWith: { (originalValue, newValue) in return newValue })
        request.httpBody = body.data
        request.httpMethod = method.rawValue
        request.httpShouldHandleCookies = allowCookies
        request.allowsCellularAccess = allowCellularNetwork
        return request
    }
}

public extension HTTPRequest {
    
    public typealias URLQueryParameters = [String:Any]
    
    public enum Method : String {
        case get = "GET"
        case head = "HEAD"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }
}

public extension HTTPRequest {
    
    public enum Task {
        case get
        case head
        case post(payload: HTTPBody)
        case put(payload: HTTPBody)
        case delete
        case patch(payload: HTTPBody)
    }
}


public extension HTTPRequest.Task {
    
    var httpMethod: HTTPRequest.Method {
        switch self {
        case .get:
            return .get
        case .head:
            return .head
        case .post:
            return .post
        case .put:
            return .put
        case .delete:
            return .delete
        case .patch:
            return .patch
        }
    }
    
    var httpBody: HTTPBody {
        switch self {
        case .get:
            return .empty
        case .head:
            return .empty
        case let .post(payload):
            return payload
        case let .put(payload):
            return payload
        case .delete:
            return .empty
        case let .patch(payload):
            return payload
        }
    }
}

//internal extension HTTPRequest {
//
//    static func queryComponents(for key: String, with value: Any) -> [(String, String)] {
//        var components: [(String, String)] = []
//
//        if let dictionary = value as? [String: Any] {
//            for (nestedKey, value) in dictionary {
//                components += queryComponents(for: "\(key)[\(nestedKey)]", with: value)
//            }
//        } else if let array = value as? [Any] {
//            for value in array {
//                components += queryComponents(for: "\(key)[]", with: value)
//            }
//        } else if let bool = value as? Bool {
//            components.append((key.urlEscaped, (bool ? "true" : "false").urlEscaped))
//        } else {
//            components.append((key.urlEscaped, "\(value)".urlEscaped))
//        }
//
//        return components
//    }
//
//    static func query(for parameters: [String: Any]) -> String {
//        return parameters.keys
//            .sorted(by: <)
//            .reduce([] as [(String, String)]) { $0 + queryComponents(for: $1, with: parameters[$1]!)}
//            .map { "\($0)=\($1)" }.joined(separator: "&")
//    }
//}
//

internal extension Dictionary where Key == String, Value == Any {
    
    func queryItems(for key: String, with value: Any) -> [(String, String)] {
        var components: [(String, String)] = []
        
        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryItems(for: "\(key)[\(nestedKey)]", with: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryItems(for: "\(key)[]", with: value)
            }
        } else if let bool = value as? Bool {
            components.append((key.urlEscaped, (bool ? "true" : "false").urlEscaped))
        } else {
            components.append((key.urlEscaped, "\(value)".urlEscaped))
        }
        
        return components
    }
    
    var urlQueryItems: [URLQueryItem] {
        return self.flatMap({ (key, value) -> [URLQueryItem] in
            return queryItems(for: key, with: value)
                .map({ (key, value) -> URLQueryItem in
                    return URLQueryItem(name: key, value: value)
                })
        })
    }
}

internal extension String {
    
    var urlEscaped: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? self
    }
}

