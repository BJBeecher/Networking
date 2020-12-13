//
//  File.swift
//  
//
//  Created by BJ Beecher on 12/13/20.
//

import Foundation

public class WebSocketCoordinator : NSObject, URLSessionWebSocketDelegate {
    // on connection
    private var didConnect : (() -> Void)?
    
    func onConnection(completion: @escaping () -> Void){
        didConnect = completion
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        // keep connection alive
        webSocketTask.keepAlive()
        // call connection
        didConnect?()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        webSocketTask.reconnect()
    }
}
