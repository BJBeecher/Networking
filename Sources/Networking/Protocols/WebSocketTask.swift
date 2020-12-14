//
//  File.swift
//  
//
//  Created by BJ Beecher on 12/14/20.
//

import Foundation

public protocol WebSocketTask : AnyObject {
    typealias Message = URLSessionWebSocketTask.Message
    func send(_ message: Message, completionHandler: @escaping (Error?) -> Void)
    func receive(completionHandler: @escaping (Result<Message, Error>) -> Void)
    func sendPing(pongReceiveHandler: @escaping (Error?) -> Void)
    func resume()
}
