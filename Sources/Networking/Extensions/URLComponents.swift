//
//  File.swift
//  
//
//  Created by BJ Beecher on 9/14/20.
//

import Foundation

extension URLComponents {
    init(scheme: String, server: Server){
        self.init()
        self.scheme = scheme
        self.host = server.host
        self.port = server.port
    }
}
