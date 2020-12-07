//
//  File.swift
//  
//
//  Created by BJ Beecher on 11/21/20.
//

import Foundation

extension URLSession {
    public static var lightWeight : Self {
        .init(configuration: .lightAndQuick)
    }
}
