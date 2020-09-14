//
//  WebSocket.swift
//  Luna
//
//  Created by BJ Beecher on 8/7/20.
//  Copyright © 2020 Renaissance Technologies. All rights reserved.
//

import Foundation

public enum WSListenerError : Error {
    case badURL
    case unknownError(_ error: Error)
}

class WSListenerService : NSObject {
    // brings in server information
    private let server : Server
    // path to call
    private let path : String
    // query items to send
    private let queryItems : [URLQueryItem]?
    // url session we will be running socket agains
    private lazy var session : URLSession = { URLSession(configuration: .default, delegate: self, delegateQueue: nil) }()
    // class that will recieved callback result
    weak var delegate : WSListenerDelegate?
    // initializer
    init(server: Server, path: String, queryItems: [URLQueryItem]? = nil, session: URLSession? = nil){
        self.server = server
        self.path = path
        self.queryItems = queryItems
    }
    // task will control starting and stoping the listener
    private var task : URLSessionWebSocketTask?
    // property will let us know current connection status
    var isConnected = false
}

// delegate methods

extension WSListenerService : URLSessionWebSocketDelegate {
    internal func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        listen(); isConnected = true; startPingInterval()
    }
    
    internal func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Socket Closed"); isConnected = false
    }
    
    internal func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("invalid url session:", error?.localizedDescription as Any)
    }
    
    internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("url session complete with error:", error?.localizedDescription as Any)
    }
}

// API

extension WSListenerService {
    var components : URLComponents {
        var components = URLComponents()
        components.scheme = "ws"
        components.host = server.host
        components.port = server.port
        components.queryItems = queryItems
        return components
    }
    
    func startListening() {
        // check our url
        guard let url = components.url else { delegate?.socket(didRecieveResult: .failure(.badURL)); return }
        // create or request object
        let request = URLRequest(url: url)
        // set our socket task
        task = session.webSocketTask(with: request)
        // start our task
        task?.resume()
    }
    
    func stopListening(){
        task?.cancel(with: .goingAway, reason: nil)
    }
    
    private func listen(){
        // start listening for messages from server
        task?.receive { [weak self] result in
            switch result {
            // on success send message message to delegate
            case .success(let message):
                self?.delegate?.socket(didRecieveResult: .success(message))
            // on failure retrun failure to delegate
            case .failure(let error):
                self?.delegate?.socket(didRecieveResult: .failure(.unknownError(error)))
            }
            // task will stop listening if this is not called after recieving a result -- stupid API!!!
            self?.listen()
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: self!.startPingInterval)
        }
    }
}
