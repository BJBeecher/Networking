import XCTest
@testable import Networking

final class HttpServiceTests: XCTestCase {
    
    func testComponents() {
        let service = NetworkService(scheme: "http", host: "localHost", port: 3000, headers: [])
        XCTAssertEqual(service.urlComponents.scheme, "http")
        XCTAssertEqual(service.urlComponents.host, "localHost")
        XCTAssertEqual(service.urlComponents.port, 3000)
    }
    
    func testGet(){
        let session = URLSessionMock()
        let text = "Hi"
        let data = text.data(using: .utf8)
        session.data = data
        let service = NetworkService(scheme: "http", host: "localHost", port: 3000, headers: [])
        service.get(path: "/poop") { (result: Result<String, HTTPError>) in
            switch result {
            case .success(let string):
                XCTAssertEqual(string, text)
            case .failure(_):
                return
            }
        }
    }
}
