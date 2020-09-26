//
//  File.swift
//  
//
//  Created by BJ Beecher on 9/19/20.
//

import Foundation

public protocol NetworkSession {
    func loadData(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
}
