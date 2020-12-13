//
//  File.swift
//  
//
//  Created by BJ Beecher on 12/13/20.
//

import Foundation

public protocol WebSocketObserver : AnyObject {
    var channelId : UUID { get }
    func webSocket(_ service: WebSocketService, didRecieveData data: Data)
}
