//
//  File.swift
//  
//
//  Created by BJ Beecher on 9/14/20.
//

import Foundation

// this class is created to essentially decode our ws listener messages

public enum WSError : Error {
    case listenerError(_ error: WSListenerError)
    case noStringInMessage
    case decodingError(_ error: Error)
}

public class WSService<T: Decodable> {
    // listener will listen for server messages
    private let listener : WSListenerService
    // init
    public init(server: Server, path: String, queryItems: [URLQueryItem]? = nil){
        listener = .init(server: server, path: path, queryItems: queryItems)
        listener.delegate = self
    }
    // return type for listener
    typealias Message = URLSessionWebSocketTask.Message
    // create completion type for
    public typealias Completion = (Result<T, WSError>) -> Void
    // storage for all completion
    private var completion : Completion?
}

// delegate method

extension WSService : WSListenerDelegate {
    func socket(didRecieveResult result: Result<Message, WSListenerError>){
        switch result {
            
        case .success(let message):
            let transform = decodeMessage(message)
            completion?(transform)
            
        case .failure(let error):
            completion?(.failure(.listenerError(error)))
        }
    }
}

// API

extension WSService {
    public func start(completion: @escaping Completion){
        // set completion for callback
        self.completion = completion
        // start the listener
        listener.startListening()
    }
    
    public func stop(){
        // stop the listener
        listener.stopListening()
    }
    
    private func decodeMessage(_ message: Message) -> Result<T, WSError> {
        switch message {
        // on string try to decode and return
        case .string(let string):
            // endode string to utf8 -- I may not need to do this
            guard let data = string.data(using: .utf8) else { return .failure(.noStringInMessage) }
            // try to decode string data
            do {
                let value = try JSONDecoder().decode(T.self, from: data)
                // on success return success value
                return .success(value)
            } catch {
                // on failure return faiure and error
                return .failure(.decodingError(error))
            }
        default:
            return .failure(.noStringInMessage)
        }
    }
}
