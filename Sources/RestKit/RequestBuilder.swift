//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/13/21.
//

import Foundation

struct RequestBuilder {
    let url : URL
    let method : HTTPMethod
    var headers = [String : String]()
}

extension RequestBuilder {
    var request : URLRequest {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        
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
