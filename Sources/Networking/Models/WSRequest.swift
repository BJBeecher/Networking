//
//  File.swift
//  
//
//  Created by BJ Beecher on 10/8/20.
//

import Foundation

struct WSRequest : Encodable {
    let id : UUID
    let event : String
    let payload : String
}
