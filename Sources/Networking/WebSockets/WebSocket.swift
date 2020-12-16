//
//  WebSocket.swift
//  Luna
//
//  Created by BJ Beecher on 8/7/20.
//  Copyright © 2020 Renaissance Technologies. All rights reserved.
//

import Foundation

public class WebSocket : NSObject {
    // task
    private let request : URLRequest
    // encoder dependency
    private let encoder : JSONEncoder
    // decoder dependency
    private let decoder : JSONDecoder
    // initializer
    public init(
        request: URLRequest,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ){
        self.request = request
        self.encoder = encoder
        self.decoder = decoder
        super.init()
        self.task.resume()
    }
    // session variable
    lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    // task variable
    lazy var task = session.webSocketTask(with: request)
    // store completion
    var observations = [ObjectIdentifier : Observation]()
    // connection status
    var isConnected = false
}

// public API

extension WebSocket {
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
    
extension WebSocket {
    func reconnect(){
        if !isConnected {
            // create new task
            task = session.webSocketTask(with: request)
            // resume task
            task.resume()
            // retry in 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: reconnect)
        }
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
    
    func didRecieveMessage(_ message: URLSessionWebSocketTask.Message){
        if let response = decodeMessageIntoResponse(message) {
            broadcastResponse(response)
        } else {
            print("Bad message from server")
        }
    }
    
    func decodeMessageIntoResponse(_ message: URLSessionWebSocketTask.Message) -> Response? {
        if case .string(let string) = message, let data = string.data(using: .utf8), let item = try? decoder.decode(Response.self, from: data) {
            return item
        } else if case .data(let data) = message, let item = try? decoder.decode(Response.self, from: data) {
            return item
        } else {
            return nil
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
    
    func startPinger(){
        // start pinging server to maintain connection
        task.sendPing { [weak self] (error) in
            // on error stop the task and try to reconnect
            if error != nil {
                // set connection status to false
                self?.isConnected = false
                // stop task -- this will call delegate method
                self?.reconnect()
                
            } else if let self = self {
                print("Socket is still alive")
                // set connection status
                self.isConnected = true
                // restart ping interval
                DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: self.startPinger)
            }
        }
    }
}

extension WebSocket : URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print(#function)
        // set connection status
        isConnected = true
        // keep connection alive
        startPinger()
        // start the listener
        webSocketTask.startListener(didRecieveMessage: didRecieveMessage)
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
    }
}

// types

extension WebSocket {
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
