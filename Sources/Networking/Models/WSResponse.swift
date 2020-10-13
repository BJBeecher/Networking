//
//  File.swift
//  
//
//  Created by BJ Beecher on 10/10/20.
//

import Foundation

struct WSResponse : Decodable {
    let channelId : UUID
    let payload : String
}
