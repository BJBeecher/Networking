//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/13/21.
//

import Foundation

public struct HTTPRequest {
    let url : URL
    let method : HTTPMethod
    let headers : [HTTPHeader]
    
    public init(url: URL, method: HTTPMethod, headers: [HTTPHeader] = .init()){
        self.url = url
        self.method = method
        self.headers = headers
    }
}

extension HTTPRequest {
    var headerDictionary : [String : String] {
        headers.reduce([String : String]()) { result, header in
            var dict = result
            dict[header.field] = header.value
            return dict
        }
    }
    
    var urlRequest : URLRequest {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headerDictionary
        
        switch method {
        case .post(let body), .put(let body):
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        case .get(let queryItems):
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            guard let url = components?.url else { preconditionFailure("Bad URL") }
            request = URLRequest(url: url)
        default:
            break
        }
        
        request.httpMethod = method.name
        
        return request
    }
}
