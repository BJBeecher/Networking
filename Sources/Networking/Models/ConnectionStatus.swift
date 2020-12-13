//
//  File.swift
//  
//
//  Created by BJ Beecher on 12/13/20.
//

import Foundation

enum ConnectionStatus {
    case pending
    case connected
    case disconnected(Error?)
}
