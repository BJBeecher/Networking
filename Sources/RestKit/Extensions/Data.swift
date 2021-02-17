//
//  File.swift
//  
//
//  Created by BJ Beecher on 2/16/21.
//

import Foundation

extension Data {
    func decode<T: Decodable>(into type: T.Type, decoder: JSONDecoder = .init()) -> T? {
        do {
            return try decoder.decode(type, from: self)
        } catch {
            print(error); return nil
        }
    }
}
