import XCTest
@testable import Networking

final class WebSocketTests: XCTestCase {
    class MockTask : WebSocketTask {
        var isResumed = false
        
        func resume() {
            isResumed = true
        }
        
        var message : Message?
        
        func send(_ message: Message, completionHandler: @escaping (Error?) -> Void) {
            self.message = message
            completionHandler(nil)
        }
        
        func receive(completionHandler: @escaping (Result<Message, Error>) -> Void) {
            if let message = message {
                completionHandler(.success(message))
            }
        }
        
        func sendPing(pongReceiveHandler: @escaping (Error?) -> Void) {
            pongReceiveHandler(nil)
        }
    }
    
    class MockObserver : WebSocketObserver {
        var channelId: UUID {
            UUID()
        }
        
        func webSocket(_ service: WebSocketService, didRecieveData data: Data) {
            
        }
    }
    
    let mockTask = MockTask()
    
    let mockObserver = MockObserver()
    
    func testAddObserver() {
        // create new serviec
        let service = WebSocketService(task: mockTask)
        // test function
        service.addObserver(mockObserver) { error in
            if error == nil {
                let bool = service.observations.contains { id, _ in id == ObjectIdentifier(self.mockObserver) }
                assert(bool)
            }
        }
    }
    
    func testRemoveObserver() {
        // create new service
        let service = WebSocketService(task: mockTask)
        // test function
        service.removeObserver(mockObserver) { error in
            if error == nil {
                let bool = service.observations.contains { id, _ in id == ObjectIdentifier(self.mockObserver) }
                assert(!bool)
            }
        }
    }
    
    func testSendReqest() {
        // create new service
        let service = WebSocketService(task: mockTask)
        // create new request
        let request = WebSocketService.Request(event: "listen", payload: "Hi")
        // test function
        service.sendRequest(request) { error in
            if error == nil {
                assert(self.mockTask.message != nil)
            }
        }
    }
    
    func testDecodeMessage() {
        // create new service
        let service = WebSocketService(task: mockTask)
        // mock response
        let response = WebSocketService.Response(channelId: .init(), payload: "Hi")
        // mock data
        let mockData = try! JSONEncoder().encode(response)
        // test function
        let decodedData = service.decodeMessage(.data(mockData))
        // assert
        assert(decodedData?.channelId == response.channelId)
        // mock string
        let mockString = String(data: mockData, encoding: .utf8)!
        // test function with string
        let decodedString = service.decodeMessage(.string(mockString))
        // assert
        assert(decodedString?.channelId == response.channelId)
    }
}
