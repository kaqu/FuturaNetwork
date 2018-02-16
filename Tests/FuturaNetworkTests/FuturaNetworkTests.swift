import XCTest
@testable import FuturaNetwork

class FuturaNetworkTests: XCTestCase {
    
    func testExample() {
        let session = NetworkSession()
        let response = try! session.do(request: HTTPRequest(url: URL(string: "https://www.google.pl")!, task: .get)).await()
        print(response)
        if case let .html(data, encoding) = response.body {
            print(String(data: data, encoding: encoding)!)
        }
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
