//
//  File.swift
//  
//
//  Created by BJ Beecher on 11/21/20.
//

import Foundation

extension URLSessionConfiguration {
    static var lightAndQuick : URLSessionConfiguration {
        // create new config
        let config = URLSessionConfiguration.ephemeral
        // create new timeout
        config.timeoutIntervalForRequest = 10
        // return config
        return config
    }
}
