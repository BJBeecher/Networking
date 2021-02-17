//
//  File.swift
//  
//
//  Created by BJ Beecher on 2/16/21.
//

import Foundation

extension Encodable {
    func encode(encoder: JSONEncoder = .init()) -> Data? {
        do {
            return try encoder.encode(self)
        } catch {
            print(error); return nil
        }
    }
}
