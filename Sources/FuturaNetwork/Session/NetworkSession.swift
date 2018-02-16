import Foundation
import FuturaAsync

public class NetworkSession {
    
    var requestTimeout: TimeInterval {
        return urlSession.configuration.timeoutIntervalForRequest
    }
    var requestHeaders: HTTPHeaders = [:]
    var allowCookies: Bool {
        return urlSession.configuration.httpCookieAcceptPolicy != .never
    }
    var allowCellularNetwork: Bool {
        return urlSession.configuration.allowsCellularAccess
    }
    var cachePolicy: CachePolicy = .ignore
    var cacheStorage: URLCache.StoragePolicy = .allowedInMemoryOnly
    
    let credentialStorage: URLCredentialStorage = URLCredentialStorage()
    let cookieStorage: HTTPCookieStorage = HTTPCookieStorage()
    
    fileprivate var urlSession: URLSession
    fileprivate var urlSessionDelegate: SessionDelegate
    
    // TODO: to complete - public creation only via factory
    internal init() {
        let sessionDelegate = SessionDelegate(with: nil)
        self.urlSessionDelegate = sessionDelegate
        let delegateQueue = OperationQueue()
        delegateQueue.underlyingQueue =  sessionDelegate.tasksQueue
        let sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.httpCookieStorage = HTTPCookieStorage.shared
        sessionConfiguration.httpCookieAcceptPolicy = .always
        sessionConfiguration.httpShouldSetCookies = true
        sessionConfiguration.httpAdditionalHeaders = [:]
        sessionConfiguration.networkServiceType = .default
        sessionConfiguration.allowsCellularAccess = true
        sessionConfiguration.timeoutIntervalForRequest = 60
        sessionConfiguration.timeoutIntervalForResource = 60 * 24 * 7
        sessionConfiguration.urlCredentialStorage = URLCredentialStorage.shared
        sessionConfiguration.urlCache = URLCache.shared
        sessionConfiguration.requestCachePolicy = .returnCacheDataElseLoad
        sessionConfiguration.httpMaximumConnectionsPerHost = 4
        sessionConfiguration.httpShouldUsePipelining = false
        // TODO: to complete - configuration
        self.urlSession = URLSession(configuration: sessionConfiguration, delegate: sessionDelegate, delegateQueue: delegateQueue)
    }
}

internal extension NetworkSession {
    
    func `do`(request: HTTPRequest) -> Future<HTTPResponse> {
        let promise = Promise<HTTPResponse>()
        let dataTask = urlSession.dataTask(with: request.urlRequest)
        urlSessionDelegate.registerTask(dataTask, with: promise)
        dataTask.resume()
        return promise.future
    }
}

// MARK: -
// MARK: session task

fileprivate class NetworkSessionTask {
    
    fileprivate let urlSessionDataTask: URLSessionDataTask
    fileprivate let responsePromise: Promise<HTTPResponse>
    fileprivate var recivedData: Data? = nil
    
    fileprivate init(urlSessionDataTask: URLSessionDataTask, responsePromise: Promise<HTTPResponse>) {
        self.urlSessionDataTask = urlSessionDataTask
        self.responsePromise = responsePromise
    }
}


// MARK: -
// MARK: session delegate

internal class SessionDelegate : NSObject, URLSessionDelegate {
    
    var cacheStorage: URLCache.StoragePolicy = .allowedInMemoryOnly // TODO: to check
    
    fileprivate let tasksQueue = DispatchQueue(label: "SessionDelegateQueue", attributes: .concurrent)
    fileprivate var activeTasks: [Int:NetworkSessionTask] = [:]
    fileprivate let securityHandler: SecurityHandler?
    internal var redirectionHandler: ((HTTPURLResponse, URLRequest)->URLRequest?)? // TODO: return enum disposition and make typealias
    
    // TODO: to complete
    internal init(with authenticationHandler: SecurityHandler?) {
        self.securityHandler = authenticationHandler
        super.init()
    }
    
    func registerTask(_ task: URLSessionDataTask, with promise: Promise<HTTPResponse>) {
        // TODO: ensure thread safety
        activeTasks[task.taskIdentifier] = NetworkSessionTask(urlSessionDataTask: task, responsePromise: promise)
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        
        guard let authenticationHandler = securityHandler else {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
            return
        }
        let authenticationResult = authenticationHandler.resolveChallenge(challenge)
        completionHandler(authenticationResult.0, authenticationResult.1)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        
        var redirectedRequest: URLRequest? = request
        
        defer {
            completionHandler(redirectedRequest)
        }
        
        guard let handler = redirectionHandler else {
            return
        }
        
        redirectedRequest = handler(response, request)
        
//        guard nil == redirectedRequest else {
//            return
//        }
//
//        guard let activeTask = activeTasks[task.taskIdentifier] else {
//            return
//        }
//
//        defer {
//            pendingRequests[task.taskIdentifier] = nil
//            task.cancel()
//        }
//
//        guard !request.responsePromise.isCompleted else {
//            return
//        }
//
//        request.responsePromise.handleMessage(.fail(with:NetworkingCommunication.Error.redirectionCancelled(response: response, data: recivedData)))
    }
}

// MARK: -
// MARK: task delegate

extension SessionDelegate : URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        guard let activeTask = activeTasks[task.taskIdentifier] else {
            return
        }
        defer {
            activeTasks[task.taskIdentifier] = nil
        }
        
        guard !activeTask.responsePromise.isCompleted else {
            return
        }
        
        if let error = error {
            try? activeTask.responsePromise.fail(with: convertError(error))
        } else if let response = task.response as? HTTPURLResponse {
            let contentType: HTTPHeader.ContentType?
            if let contentTypeHeader = response.allHeaderFields["Content-Type"] as? String {
               contentType = HTTPHeader.ContentType(withHeaderValue: contentTypeHeader)
            } else {
                contentType = HTTPHeader.ContentType(withHeaderValue: response.mimeType)
            }
            
            let responseBody = HTTPBody(with: activeTask.recivedData, contentType: contentType)
            let httpResponse = HTTPResponse(code: HTTPStatusCode(withCode: response.statusCode), headers: response.allHeaderFields as? HTTPHeaders ?? [:], body: responseBody)
            try? activeTask.responsePromise.fulfill(with: httpResponse)
        } else if let response = task.response {
            try? activeTask.responsePromise.fail(with: NetworkError.unsupportedResponse(response))
        } else {
            try? activeTask.responsePromise.fail(with: NetworkError.unknownError(NetworkError.invalidResponse, info: "No error or response while completing network task"))
        }
    }
}

// MARK: -
// MARK: data delegate

extension SessionDelegate : URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        guard let activeTask = activeTasks[dataTask.taskIdentifier] else {
            return
        }
        
        guard !activeTask.responsePromise.isCompleted else {
            dataTask.cancel()
            activeTasks[dataTask.taskIdentifier] = nil
            return
        }

        if var recivedData = activeTask.recivedData {
            recivedData.append(data)
            activeTask.recivedData = recivedData
        } else {
            activeTask.recivedData = data
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
            completionHandler(CachedURLResponse(response: proposedResponse.response,
                                                data: proposedResponse.data,
                                                userInfo: proposedResponse.userInfo,
                                                storagePolicy: cacheStorage))
        // TODO: to complete
    }
}

// MARK: -
// MARK: error conversion

internal extension SessionDelegate {
    
    func convertError(_ error: Error) -> NetworkError {
        switch (error as NSError).code { // TODO: to complete - handle more cases
        case NSURLErrorTimedOut:
            return NetworkError.requestTimeout
        case NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet:
            return NetworkError.noConnection
        default:
            return NetworkError.unknownError(error, info: nil)
        }
    }
}
