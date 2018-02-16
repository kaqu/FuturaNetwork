import Foundation

public class HTTPResponse {
    public var code: HTTPStatusCode
    public var headers: HTTPHeaders
    public var body: HTTPBody
    
    internal init(code: HTTPStatusCode, headers: HTTPHeaders, body: HTTPBody) {
        self.code = code
        self.headers = headers
        self.body = body
    }
}
