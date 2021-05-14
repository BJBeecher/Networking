//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/13/21.
//

import Foundation

enum HTTPMethod {
    case get(_ queryItems: [URLQueryItem])
    case post(_ body: Data)
    case put(_ body: Data)
    case delete
}

extension HTTPMethod {
    var name : String {
        switch self {
        case .get: return "Get"
        case .post: return "Post"
        case .put: return "Put"
        case .delete: return "Delete"
        }
    }
}

