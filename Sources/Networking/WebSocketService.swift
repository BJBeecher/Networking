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

class WebSocketService : NSObject, URLSessionWebSocketDelegate {
    // url scheme
    private let scheme : String
    // url host
    private let host : String
    // url port
    private let port : Int?
    // request headers
    private let headers : [HttpHeader]
    // encoder dependency
    private let encoder : JSONEncoder
    // decoder dependency
    private let decoder : JSONDecoder
    // initializer
    init(scheme: String = "ws", host: String, port: Int?, headers: [HttpHeader], encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()){
        self.scheme = scheme
        self.host = host
        self.port = port
        self.headers = headers
        self.encoder = encoder
        self.decoder = decoder
    }
    // computed request object
    private var request : URLRequest {
        // contruct new url
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        // construct request
        let request = URLRequest(url: components.url!)
        // return request
        return request
    }
    // url session we will be running socket agains
    private lazy var session : URLSession = { URLSession(configuration: .default, delegate: self, delegateQueue: nil) }()
    // task will control starting and stoping the listener
    private var task : URLSessionWebSocketTask?
    // property will let us know current connection status
    private var connectionStatus : ConnectionStatus = .disconnected(nil)
    // connection completion
    private var onConnection : (() -> Void)?
    // store completion
    private var listeners = [ WSListener: (Data?) -> Void ]()
    
    // delegate methods
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print(#function)
        // store connection status
        connectionStatus = .connected
        // start listening for messages from server
        listen()
        // periodically check for connections with ping
        startPingInterval()
        // re-add any deleted subscriptions
        listeners.forEach { (listener, _) in
            subscribeListener(listener) { _ in }
        }
        // let requester know we are connected
        onConnection?()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print(#function)
        // change connection status
        connectionStatus = .disconnected(nil)
        // try to reconnect
        reconnect()
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print(#function)
        // change connection status
        connectionStatus = .disconnected(error)
        // retry after 3 seconds
        reconnect()
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print(#function)
        // change connectionStatus
        connectionStatus = .disconnected(error)
        // reconnect
        reconnect()
    }
}

// API

extension WebSocketService {
    @discardableResult
    public func createListener<T: AnyObject, D: Decodable>(_ observer: T, channel: UUID, completion: @escaping (T, D) -> Void) -> () -> Void {
        print(#function)
        // create new listener object -- when the completion is called by service it will check if observer is allocated and remove if it isn't
        let listener = WSListener(id: UUID(), channelId: channel)
        // send listen request to server to let us subscribe to channel
        subscribeListener(listener) { [weak self] error in
            if let error = error {
                print(error)
                self?.listeners.removeValue(forKey: listener)
            } else {
                // store callback and type in dictionary
                self?.listeners[listener] = { [weak self, weak observer] data in
                    if let observer = observer {
                        guard let data = data, let value = try? self?.decoder.decode(D.self, from: data) else { return }
                        completion(observer, value)
                    } else {
                        self?.listeners.removeValue(forKey: listener)
                    }
                }
            }
        }
        // return cancellation
        return { [weak self] in
            self?.unsubscribeListener(listener)
            print("listener removed for: \(listener)")
        }
    }
    
    private func subscribeListener(_ listener: WSListener, completion: @escaping (Error?) -> Void){
        print(#function)
        sendRequest(event: "listen", payload: listener, completion: completion)
    }
    
    private func unsubscribeListener(_ listener: WSListener){
        print(#function)
        sendRequest(event: "ignore", payload: listener) { error in
            guard error == nil else { return }
            self.listeners.removeValue(forKey: listener)
        }
    }
    
    private func sendRequest<T: Encodable>(event: String, payload: T, completion: @escaping (Error?) -> Void){
        print(#function)
        connect { [weak self] in
            // check self allocation
            guard let self = self else { return }
            // do catch block
            do {
                // encode message
                let payloadData = try self.encoder.encode(payload)
                // convert to jsonstring
                guard let payload = String(data: payloadData, encoding: .utf8) else { throw WSError.encodingError() }
                // construct new item
                let request = WSRequest(id: UUID(), event: event, payload: payload)
                // encode item
                let data = try self.encoder.encode(request)
                // send message to ws
                self.task?.send(.data(data)) { error in
                    // check for error
                    guard let error = error else { return completion(nil) }
                    // send error to completion block
                    completion(error)
                }
            } catch {
                completion(error)
            }
        }
    }
    
    private func listen(){
        print(#function)
        connect { [ weak self] in
            // start listening for messages from server
            self?.task?.receive { [weak self] result in
                print(result)
                // check for self
                guard let self = self else { return }
                // examine result
                if case .success(let message) = result, let response = self.decodeMessage(message) {
                    self.broadcastResponse(response)
                }
                // task will stop listening if this is not called after recieving a result -- stupid API!!!
                self.listen()
            }
        }
    }
    
    private func decodeMessage(_ message: URLSessionWebSocketTask.Message) -> WSResponse? {
        print(#function)
        if case .string(let string) = message, let data = string.data(using: .utf8), let item = try? decoder.decode(WSResponse.self, from: data) {
            return item
        } else if case .data(let data) = message, let item = try? decoder.decode(WSResponse.self, from: data) {
            return item
        } else {
            return nil
        }
    }
    
    private func broadcastResponse(_ response: WSResponse){
        print(#function)
        for (listener, completion) in listeners {
            if listener.channelId == response.channelId {
                completion(response.payload.data(using: .utf8))
            }
        }
    }
    
    private func connect(completion: (() -> Void)? = nil) {
        print(#function)
        // check that socket is not already connected
        guard case .disconnected(_) = connectionStatus else { completion?(); return }
        // set status
        connectionStatus = .pending
        // set completion
        onConnection = completion
        // add token to request header
        var request = self.request
        // check for token
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.field) }
        // init the task -- this needs to be reinitialized every time we want to connect
        task = session.webSocketTask(with: request)
        // start the task
        task?.resume()
    }
    
    private func reconnect(){
        print(#function)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.connect()
        }
    }
    
    private func startPingInterval(){
        print(#function)
        // check for connection
        guard case .connected = connectionStatus else { return }
        // start pinging server to maintain connection
        task?.sendPing { [weak self] (error) in
            // check that self is allocated
            guard let self = self else { return }
            // on error stop the task
            if let error = error {
                // stop task
                self.task?.cancel(with: .abnormalClosure, reason: nil)
                // change connection status
                self.connectionStatus = .disconnected(error)
            } else {
                // set connection status
                self.connectionStatus = .connected
                // restart ping interval
                DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: self.startPingInterval)
            }
        }
    }
}

// types

extension WebSocketService {
    enum ConnectionStatus {
        case pending
        case connected
        case disconnected(Error?)
    }
}
