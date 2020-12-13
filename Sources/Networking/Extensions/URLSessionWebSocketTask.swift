//
//  File.swift
//  
//
//  Created by BJ Beecher on 12/13/20.
//

import Foundation

extension URLSessionWebSocketTask {
    func reconnect(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: resume)
    }
    
    func keepAlive(){
        // start pinging server to maintain connection
        sendPing { [weak self] (error) in
            // on error stop the task and try to reconnect
            if error != nil {
                // stop task
                self?.cancel(with: .abnormalClosure, reason: nil)
                // try to reconnect
                self?.reconnect()
                
            } else if let self = self {
                // restart ping interval
                DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: self.keepAlive)
            }
        }
    }
}
