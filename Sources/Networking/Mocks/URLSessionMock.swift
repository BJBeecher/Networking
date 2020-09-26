//
//  File.swift
//  
//
//  Created by BJ Beecher on 9/20/20.
//

import Foundation

class URLSessionMock : NetworkSession {
    var data : Data?
    var response : URLResponse?
    var error : Error?
    
    func loadData(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        completionHandler(data, response, error)
    }
}
