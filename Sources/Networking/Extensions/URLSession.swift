//
//  File.swift
//  
//
//  Created by BJ Beecher on 9/19/20.
//

import Foundation

extension URLSession : NetworkSession {
    public func loadData(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void){
        let task = dataTask(with: request, completionHandler: completionHandler)
        
        task.resume()
    }
}
