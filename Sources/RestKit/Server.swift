//
//  File.swift
//  
//
//  Created by BJ Beecher on 9/12/20.
//

import Foundation

public enum RestError : Error {
    case responseNotHTTP
    case dataAbsentFromResponse
    case clientError(_ message: String?)
    case serverError(_ message: String?)
    case unknownError(_ error: Error)
    case encodingError
    case decodingError
    case accessDenied(_ message: String?)
    case requestError
    case badURL
}

public class Server {
    
    // scheme
    let scheme : String
    let host : String
    let port : Int?
    
    // url session
    let loader : DataLoader
    
    public init(
        scheme: String,
        host: String,
        port: Int? = nil,
        loader : DataLoader = URLSession.shared
    ) {
        self.scheme = scheme
        self.host = host
        self.port = port
        self.loader = loader
    }
}

// public networking methods

extension Server {
    @discardableResult
    public func get<Value: Decodable>(path: String, queryItems: [URLQueryItem]? = nil, headers: [Header] = .init(), completion: @escaping (Result<Value, RestError>) -> Void) -> CancellableObject? {
        // check url
        guard let url = url(path: path, queryItems: queryItems) else { completion(.failure(.badURL)); return nil }
        // create request with url dependency
        var request = URLRequest(url: url)
        // set method
        request.httpMethod = "Get"
        // set headers
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.field) }
        // return loader
        return loader.load(with: request) { result in
            switch result {
            
            case .success(let data):
                if let value = data.decode(into: Value.self) {
                    completion(.success(value))
                } else {
                    completion(.failure(.decodingError))
                }
                
            case .failure(let error):
                completion(.failure(.unknownError(error)))
            }
        }
    }
    
    @discardableResult
    public func post<Body: Encodable>(path: String, headers: [Header] = .init(), body: Body, completion: @escaping (RestError?) -> Void) -> CancellableObject? {
        // check url
        guard let url = url(path: path) else { completion(.badURL); return nil }
        // create request with url
        var request = URLRequest(url: url)
        // set method
        request.httpMethod = "Post"
        // encode
        guard let data = body.encode() else { completion(.encodingError); return nil }
        // set body
        request.httpBody = data
        // set headers
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.field) }
        // add json header
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // create the task
        return loader.load(with: request) { result in
            switch result {
            
            case .success(_):
                completion(nil)
                
            case .failure(let error):
                completion(.unknownError(error))
            }
        }
    }
    
    public func put<Body: Encodable>(path: String, headers: [Header] = .init(), body: Body, completion: @escaping (RestError?) -> Void) -> CancellableObject? {
        // check url
        guard let url = url(path: path) else { completion(.badURL); return nil }
        // create request with url
        var request = URLRequest(url: url)
        // set method
        request.httpMethod = "Put"
        // encode
        guard let data = body.encode() else { completion(.encodingError); return nil }
        // set body
        request.httpBody = data
        // set headers
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.field) }
        // add json header
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // return cancellable load
        return loader.load(with: request) { result in
            switch result {
            
            case .success(_):
                completion(nil)
                
            case .failure(let error):
                completion(.unknownError(error))
            }
        }
    }
    
    public func delete(path: String, headers: [Header] = .init(), completion: @escaping (RestError?) -> Void) -> CancellableObject? {
        // check url
        guard let url = url(path: path) else { completion(.badURL); return nil }
        // create request with url
        var request = URLRequest(url: url)
        // set method
        request.httpMethod = "Delete"
        // set headers
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.field) }
        // return cancellable load
        return loader.load(with: request) { result in
            switch result {
            
            case .success(_):
                completion(nil)
                
            case .failure(let error):
                completion(.unknownError(error))
            }
        }
    }
}

// helper API

extension Server {
    func url(path: String, queryItems: [URLQueryItem]? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        components.path = path
        components.queryItems = queryItems
        return components.url
    }
}
