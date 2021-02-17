//
//  File.swift
//  
//
//  Created by BJ Beecher on 2/16/21.
//

import Foundation

public protocol DataLoader {
    @discardableResult
    func load(with request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) -> CancellableObject
}
