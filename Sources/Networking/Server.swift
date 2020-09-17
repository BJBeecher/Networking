//
//  File.swift
//  
//
//  Created by BJ Beecher on 9/14/20.
//

import Foundation

public class Server {
    let host : String
    let port : Int?
    private (set) var headers : [HttpHeader]
    
    public init(host: String, port: Int? = nil, headers: [HttpHeader]){
        self.host = host
        self.port = port
        self.headers = headers
    }
}

// Server API

extension Server {
    public func addHeader(_ header: HttpHeader){
        headers.append(header)
    }
    
    public func removeHeader(for field: String){
        headers = headers.filter { $0.field != field }
    }
}
