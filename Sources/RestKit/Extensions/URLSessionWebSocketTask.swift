//
//  File.swift
//  
//
//  Created by BJ Beecher on 12/13/20.
//

import Foundation

extension URLSessionWebSocketTask : WebSocketTask {
    func startListener(didRecieveMessage: @escaping (Message) -> Void){
        // start listening for messages from server
        receive { [weak self] result in
            // examine result
            if case .success(let message) = result {
                didRecieveMessage(message)
            }
            // task will stop listening if this is not called after recieving a result
            self?.startListener(didRecieveMessage: didRecieveMessage)
        }
    }
}
