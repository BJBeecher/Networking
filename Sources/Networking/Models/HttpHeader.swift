//
//  File.swift
//  
//
//  Created by BJ Beecher on 9/12/20.
//

import Foundation

public struct HTTPHeader {
    let value : String
    let field : String
    
    public init(value: String, field: String){
        self.value = value
        self.field = field
    }
}
