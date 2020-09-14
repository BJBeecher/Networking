//
//  File.swift
//  
//
//  Created by BJ Beecher on 9/14/20.
//

import Foundation

protocol WSListenerDelegate : AnyObject {
    func socket(didRecieveResult result: Result<URLSessionWebSocketTask.Message, WSListenerError>)
}
