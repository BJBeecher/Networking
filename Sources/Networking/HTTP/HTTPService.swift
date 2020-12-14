//
//  File.swift
//  
//
//  Created by BJ Beecher on 9/12/20.
//

import Foundation

public enum HTTPError : Error {
    case responseNotHTTP
    case dataAbsentFromResponse
    case clientError(_ message: String?)
    case serverError(_ message: String?)
    case unknownError(_ error: Error)
    case encodingError(_ error: Error)
    case decodingError(_ error: Error)
    case accessDenied(_ message: String?)
    case requestError
    case badURL
}

public class HTTPService {
    // url session
    private var session : URLSession
    // encoder
    private let encoder : JSONEncoder
    // decoder
    private let decoder : JSONDecoder
    // init
    public init(
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init(),
        session : URLSession = .shared
    ) {
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }
}

// public networking methods

extension HTTPService {
    public func get<Value: Decodable>(url: URL?, headers: [HTTPHeader], completion: @escaping (Result<Value, HTTPError>) -> Void) {
        // check url
        guard let url = url else { return completion(.failure(.badURL)) }
        // create request with url dependency
        var request = URLRequest(url: url)
        // set method
        request.httpMethod = "Get"
        // set headers
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.field) }
        // create new datatask
        session.dataTask(with: request) { [weak self] (data, response, error) in
            // check for error
            if let error = error { return completion(.failure(.unknownError(error))) }
            // check response for error
            if let error = self?.responseError(response, data: data) { return completion(.failure(error)) }
            // check for data
            guard let data = data, let self = self else { return completion(.failure(.dataAbsentFromResponse)) }
            // decode the data to object
            do {
                // decode data
                let value = try self.decoder.decode(Value.self, from: data)
                // send to completion
                completion(.success(value))
            } catch {
                print(error); completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
    
    public func post<Body: Encodable>(url: URL?, headers: [HTTPHeader], body: Body, completion: @escaping (HTTPError?) -> Void){
        // check url
        guard let url = url else { return completion(.badURL) }
        // create request with url
        var request = URLRequest(url: url)
        // set method
        request.httpMethod = "Post"
        // set body
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            return completion(.encodingError(error))
        }
        // set headers
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.field) }
        // add json header
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // create the task
        session.dataTask(with: request) { [weak self] (data, response, error) in
            // check error
            if let error = error { completion(.unknownError(error)); return }
            // check response for error
            if let responseError = self?.responseError(response, data: data) { completion(responseError); return }
            // all good return nil
            completion(nil)
        }.resume()
    }
    
    public func put<Body: Encodable>(url: URL?, headers: [HTTPHeader], body: Body, completion: @escaping (HTTPError?) -> Void){
        // check url
        guard let url = url else { return completion(.badURL) }
        // create request with url
        var request = URLRequest(url: url)
        // set method
        request.httpMethod = "Put"
        // set body data
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            return completion(.encodingError(error))
        }
        // set headers
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.field) }
        // add json header
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // create the task
        session.dataTask(with: request) { [weak self] (data, response, error) in
            // check error
            if let error = error { return completion(.unknownError(error)) }
            // check response for error
            if let responseError = self?.responseError(response, data: data) { return completion(responseError) }
            // all good return nil
            completion(nil)
        }.resume()
    }
    
    public func delete(url: URL?, headers: [HTTPHeader], completion: @escaping (HTTPError?) -> Void){
        // check url
        guard let url = url else { return completion(.badURL) }
        // create request with url
        var request = URLRequest(url: url)
        // set method
        request.httpMethod = "Delete"
        // set headers
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.field) }
        // create the task
        session.dataTask(with: request) { [weak self] (data, response, error) in
            // check error
            if let error = error { return completion(.unknownError(error)) }
            // check response for error
            if let responseError = self?.responseError(response, data: data) { return completion(responseError) }
            // all good return nil
            completion(nil)
        }.resume()
    }
}

// helper API

extension HTTPService {
    func responseError(_ response: URLResponse?, data: Data?) -> HTTPError? {
        // check type or httpurlresponse we should get this ever time since all request are http
        guard let httpResponse = response as? HTTPURLResponse else { return .responseNotHTTP }
        // switch on the code to return necessary error
        switch httpResponse.statusCode {
            case 401, 403:
                // grab message
                let message : String? = decodeData(data: data)
                // return error
                return .accessDenied(message)
            case 400..<500:
                // grab message
                let message : String? = decodeData(data: data)
                // return error
                return .clientError(message)
            case 500..<600:
                // grab message
                let message : String? = decodeData(data: data)
                // return error
                return .serverError(message)
            default:
                // no error try to decode data
                return nil
        }
    }
    
    func decodeData<Value: Decodable>(data: Data?) -> Value? {
        // check for data
        guard let data = data else { return nil }
        // try to decode the data
        do {
            let value = try decoder.decode(Value.self, from: data)
            // return value
            return value
        } catch {
            print(error); return nil
        }
    }
}


