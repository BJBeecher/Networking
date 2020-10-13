//
//  File.swift
//  
//
//  Created by BJ Beecher on 10/7/20.
//

import Foundation

public struct Server {
    public let host : String
    public let port : Int?
    
    public init(host: String, port: Int?){
        self.host = host
        self.port = port
    }
}
