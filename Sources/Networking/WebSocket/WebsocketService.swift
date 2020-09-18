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
}

public class WebsocketService<T: Decodable> : NSObject, URLSessionWebSocketDelegate {
    // url constructor
    private let components : URLComponents
    // headers
    private let headers : [HttpHeader]
    // initializer
    init(scheme: String = "ws", components: URLComponents, headers: [HttpHeader], path: String, queryItems: [URLQueryItem]? = nil){
        // create new components instance
        var components = components
        components.scheme = scheme
        components.path = path
        components.queryItems = queryItems
        // store components dependency
        self.components = components
        // store header dependency
        self.headers = headers
    }
    // url session we will be running socket agains
    private lazy var session : URLSession = { URLSession(configuration: .default, delegate: self, delegateQueue: nil) }()
    // task will control starting and stoping the listener
    private var task : URLSessionWebSocketTask?
    // property will let us know current connection status
    var isConnected = false
    // completion type for listener
    public typealias Completion = (Result<T, WSError>) -> Void
    // store completion
    private var completion : Completion?
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        listen(); isConnected = true; startPingInterval()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Socket Closed"); isConnected = false
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("invalid url session:", error?.localizedDescription as Any)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("url session complete with error:", error?.localizedDescription as Any)
    }
}

// API

extension WebsocketService {
    
    public func startListening(completion: @escaping Completion) {
        // save call back for delegate method access
        self.completion = completion
        // check our url
        guard let url = components.url else { completion(.failure(.badURL)); return }
        // create or request object
        var request = URLRequest(url: url)
        // add appropriate headers to request
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.field) }
        // set our socket task
        task = session.webSocketTask(with: request)
        // start our task
        task?.resume()
    }
    
    public func stopListening(){
        task?.cancel(with: .goingAway, reason: nil)
    }
    
    private func listen(){
        // start listening for messages from server
        task?.receive { [weak self] result in
            switch result {
            // on success send message message to delegate
            case .success(let message):
                self?.decodeMessage(message: message)
            // on failure retrun failure to delegate
            case .failure(let error):
                self?.completion?(.failure(.unknownError(error)))
            }
            // task will stop listening if this is not called after recieving a result -- stupid API!!!
            self?.listen()
        }
    }
    
    private func decodeMessage(message: URLSessionWebSocketTask.Message) {
        switch message {
        // on string lets encode and then try to decode
        case .string(let string):
            // convert string to data
            guard let data = string.data(using: .utf8) else { completion?(.failure(.badMessage)); return }
            // decode the data
            do {
                // decode data
                let value = try JSONDecoder().decode(T.self, from: data)
                // send value to completion
                completion?(.success(value))
            } catch {
                print(error)
                completion?(.failure(.decodingError(error)))
            }
        default:
            completion?(.failure(.badMessage))
        }
    }
    
    private func startPingInterval(){
        // check for connection
        guard isConnected else { return }
        // start pinging server to maintain connection
        task?.sendPing { [weak self] (error) in
            // on error stop the task
            if let error = error {
                print(error.localizedDescription)
                self?.task?.cancel(with: .abnormalClosure, reason: nil)
                self?.isConnected = false
                return
            }
            
            // on success ping again in 30 seconds
            self?.isConnected = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                self?.startPingInterval()
            }
        }
    }
}
