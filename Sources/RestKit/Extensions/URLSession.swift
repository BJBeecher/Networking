//
//  File.swift
//  
//
//  Created by BJ Beecher on 2/16/21.
//

import Foundation

extension URLSession : DataLoader {
    @discardableResult
    public func load(with request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) -> CancellableObject {
        let task = dataTask(with: request) { (data, _, error) in
            if let data = data {
                completion(.success(data))
            } else if let error = error {
                completion(.failure(DataTaskError.urlSessionError(error)))
            } else {
                completion(.failure(DataTaskError.noData))
            }
        }
        
        defer {
            task.resume()
        }
        
        return task
    }
    
    enum DataTaskError : Error {
        case noData
        case urlSessionError(_ error: Error)
    }
}
