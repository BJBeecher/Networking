//
//  File.swift
//  
//
//  Created by BJ Beecher on 9/12/20.
//

import Foundation
import Combine

public class REST {
    typealias LoadData = (URLRequest) -> URLSession.DataTaskPublisher
    
    let loadData : LoadData
    
    init(loadData: @escaping LoadData){
        self.loadData = loadData
    }
}

// public API

public extension REST {
    func request(_ url: URL, method: HTTPMethod, headers: [String : String] = .init()) -> AnyPublisher<Data, Error> {
        let mappedHeaders = headers.map(HTTPHeader.init)
        let request = HTTPRequest(url: url, method: method, headers: mappedHeaders)
        let urlRequest = request.urlRequest
        
        return loadData(urlRequest)
            .mapError(Failure.dataTaskError)
            .map(\.data)
            .eraseToAnyPublisher()
    }
    
    func perform(_ request: HTTPRequest) -> AnyPublisher<Data, Error> {
        let urlRequest = request.urlRequest
        
        return loadData(urlRequest)
            .mapError(Failure.dataTaskError)
            .map(\.data)
            .eraseToAnyPublisher()
    }
}

// static properties

public extension REST {
    static let shared = REST(loadData: URLSession.shared.dataTaskPublisher)
}
