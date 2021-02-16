//
//  File.swift
//  
//
//  Created by BJ Beecher on 12/13/20.
//

import Foundation

protocol WebSocketSession {
    // delegate init
    init(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue: OperationQueue?)
    // socket starter
    func webSocketTask(with: URLRequest) -> URLSessionWebSocketTask
}
