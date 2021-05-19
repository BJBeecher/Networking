//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/19/21.
//

import Foundation

public struct HTTPHeader {
    let value : String
    let field : String
    
    public init(_ value: String, for field: String){
        self.value = value
        self.field = field
    }
}
