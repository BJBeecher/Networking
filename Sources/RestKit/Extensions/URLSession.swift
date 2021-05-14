//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/13/21.
//

import Foundation
import Combine

extension URLSession {
    func erasedDataTaskPublisher(with request: URLRequest) -> AnyPublisher<Data, Error> {
        dataTaskPublisher(for: request)
            .mapError(Failure.dataTaskError)
            .map(\.data)
            .eraseToAnyPublisher()
    }
}
