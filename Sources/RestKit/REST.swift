//
//  File.swift
//  
//
//  Created by BJ Beecher on 9/12/20.
//

import Foundation
import Combine

typealias LoadData = (URLRequest) -> AnyPublisher<Data, Error>

public class REST {
    
    let loadData : LoadData
    
    init(loadData: @escaping LoadData){
        self.loadData = loadData
    }
    
    func request(_ url: URL, method: HTTPMethod, headers: [String : String] = .init()) -> AnyPublisher<Data, Error> {
        let builder = RequestBuilder(url: url, method: method, headers: headers)
        
        return loadData(builder.request)
    }
}

// static properties

extension REST {
    static let shared = REST(loadData: URLSession.shared.erasedDataTaskPublisher)
}
