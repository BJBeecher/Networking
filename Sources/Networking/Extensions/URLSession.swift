//
//  File.swift
//  
//
//  Created by BJ Beecher on 11/21/20.
//

import Foundation

extension URLSession : NetworkSession {
    public func loadData(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        dataTask(with: request, completionHandler: completionHandler)
    }
    
    public static var lightWeight : Self {
        .init(configuration: .lightAndQuick)
    }
}

extension URLSession : WebSocketSession {
    
}
