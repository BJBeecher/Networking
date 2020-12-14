//
//  WebSocket.swift
//  Luna
//
//  Created by BJ Beecher on 8/7/20.
//  Copyright © 2020 Renaissance Technologies. All rights reserved.
//

import Foundation

public enum WSError : Error {
    case badURL
    case badMessage
    case decodingError(_ error: Error)
    case unknownError(_ error: Error)
    case encodingError(_ error: Error? = nil)
}

public class WebSocketService {
    // task
    private let task : WebSocketTask
    // encoder dependency
    private let encoder : JSONEncoder
    // decoder dependency
    private let decoder : JSONDecoder
    // initializer
    public init(
        task: WebSocketTask,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ){
        self.task = task
        self.encoder = encoder
        self.decoder = decoder
        // start the good ole guy
        self.task.resume()
    }
    // store completion
    var observations = [ObjectIdentifier : Observation]()
}

// public API

extension WebSocketService {
    public func addObserver(_ observer: WebSocketObserver, completion: @escaping (Error?) -> Void) {
        // create request
        let request = Request(event: "listen", payload: observer.channelId)
        // send listen request to server to let us subscribe to channel
        sendRequest(request) { [weak self] error in
            if let error = error {
                completion(error)
            } else {
                // create new object id
                let id = ObjectIdentifier(observer)
                // append to list
                self?.observations[id] = Observation(observer: observer)
                // send completion to request
                completion(nil)
            }
        }
    }
    
    public func removeObserver(_ observer: WebSocketObserver, completion: @escaping (Error?) -> Void){
        // create request
        let request = Request(event: "ignore", payload: observer.channelId)
        // send ignore request to server
        sendRequest(request) { [weak self] error in
            if let error = error {
                completion(error)
            } else {
                // create object id
                let id = ObjectIdentifier(observer)
                // remove object from list
                self?.observations.removeValue(forKey: id)
            }
        }
    }
}

// internal API
    
extension WebSocketService {
    func onConnect(){
        // send all existing observers to server
        observations.forEach { id, observation in
            if let observer = observation.observer {
                // create new request
                let request = Request(event: "listen", payload: observer.channelId)
                // send the request
                sendRequest(request) { _ in }
            } else {
                observations.removeValue(forKey: id)
            }
        }
        // start the listener
        listen()
    }
    
    func sendRequest<T:Encodable>(_ request: Request<T>, completion: @escaping (Error?) -> Void){
        do {
            // encode request
            let data = try encoder.encode(request)
            // send message to ws
            task.send(.data(data)) { error in
                // check for error
                guard let error = error else { return completion(nil) }
                // send error to completion block
                completion(error)
            }
        } catch {
            completion(error)
        }
    }
    
    func listen(){
        // start listening for messages from server
        task.receive { [weak self] result in
            // examine result
            if case .success(let message) = result, let response = self?.decodeMessage(message) {
                self?.broadcastResponse(response)
            }
            // task will stop listening if this is not called after recieving a result
            self?.listen()
        }
    }
    
    func decodeMessage(_ message: URLSessionWebSocketTask.Message) -> Response? {
        if case .string(let string) = message, let data = string.data(using: .utf8), let item = try? decoder.decode(Response.self, from: data) {
            return item
        } else if case .data(let data) = message, let item = try? decoder.decode(Response.self, from: data) {
            return item
        } else {
            print("Bad message"); return nil
        }
    }
    
    func broadcastResponse(_ response: Response){
        for (id, observation) in observations {
            if let observer = observation.observer {
                if response.channelId == observer.channelId, let data = response.payload.data(using: .utf8) {
                    observer.webSocket(self, didRecieveData: data)
                }
            } else {
                observations.removeValue(forKey: id)
            }
        }
    }
}

// types

extension WebSocketService {
    struct Observation {
        weak var observer : WebSocketObserver?
    }
    
    struct Request<T:Encodable> : Encodable {
        let event : String
        let payload : T
    }
    
    struct Response : Codable {
        let channelId : UUID
        let payload : String
    }
}

// shared instance

extension WebSocketService {
    public static func standard(request: URLRequest) -> WebSocketService {
        // create coordinator
        let coordinator = WebSocketCoordinator()
        // create new url session
        let session = URLSession(configuration: .default, delegate: coordinator, delegateQueue: nil)
        // create new websocket task
        let task = session.webSocketTask(with: request)
        // create service
        let service = WebSocketService(task: task)
        // set on connect
        coordinator.onConnection(completion: service.onConnect)
        // return the new service
        return service
    }
}
