import XCTest
@testable import RestKit

class RestKitTests : XCTestCase {
    
    var server : Server!
    
    override func setUp() {
        let scheme = "https"
        let host = "CoolHost"
        let port = 3000
        server = Server(scheme: scheme, host: host, port: port)
    }
    
    func testURLGeneration(){
        // when
        let url = server.url(path: "/boats")
        
        // then
        XCTAssertEqual(url, URL(string: "https://CoolHost:3000/boats"))
    }
}
