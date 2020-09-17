//
//  File.swift
//  
//
//  Created by BJ Beecher on 9/12/20.
//

import Foundation

public enum HttpError : Error {
    case responseNotHTTP
    case dataAbsentFromResponse
    case clientError(_ message: String?)
    case serverError(_ message: String?)
    case unknownError(_ error: Error)
    case encodingError(_ error: Error)
    case decodingError(_ error: Error)
    case accessDenied(_ message: String?)
    case requestError
    case urlError
}

public class HttpService {
    
    private let session : URLSession
    
    let components : URLComponents
    
    private (set) var headers : [HttpHeader]
    
    public init(session : URLSession = .shared, scheme: String = "http", host: String, port: Int? = nil, headers: [HttpHeader] = [HttpHeader]()) {
        // set our session
        self.session = session
        // create components object
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        // set our components
        self.components = components
        // set our headers
        self.headers = headers
    }
}

// API

extension HttpService {
    
    public func addHeader(_ header: HttpHeader){
        headers.append(header)
    }
    
    public func removeHeader(for field: String){
        headers = headers.filter { $0.field != field }
    }
    
    public func get<Value: Decodable>(path: String, queryItems: [URLQueryItem]? = nil, completion: @escaping (Result<Value, HttpError>) -> Void) {
        // pull in components
        var components = self.components
        // set path
        components.path = path
        // add query items
        components.queryItems = queryItems
        // check url
        guard let url = components.url else { completion(.failure(.urlError)); return }
        // create request with url dependency
        var request = URLRequest(url: url)
        // set method
        request.httpMethod = "Get"
        // set headers
        headers.forEach { header in request.addValue(header.value, forHTTPHeaderField: header.field) }
        // create new datatask
        let task = session.dataTask(with: request) { [weak self] (data, response, error) in
            // check for error
            if let error = error { completion(.failure(.unknownError(error))); return }
            // check response for error
            if let error = self?.responseError(response, data: data) { completion(.failure(error)); return }
            // check for data
            guard let data = data else { completion(.failure(.dataAbsentFromResponse)); return }
            // decode the data to object
            do {
                let value = try JSONDecoder().decode(Value.self, from: data); completion(.success(value))
            } catch {
                print(error); completion(.failure(.decodingError(error)))
            }
        }
        // start the task
        task.resume()
    }
    
    public func post<Body: Encodable>(path: String, body: Body, completion: @escaping (HttpError?) -> Void){
        // pull in components
        var components = self.components
        // add path
        components.path = path
        // check url
        guard let url = components.url else { completion(.urlError); return }
        // create request with url
        var request = URLRequest(url: url)
        // set method
        request.httpMethod = "Post"
        // set body data
        do { let data = try JSONEncoder().encode(body); request.httpBody = data } catch { print(error); completion(.encodingError(error)); return }
        // set headers
        headers.forEach { header in request.addValue(header.value, forHTTPHeaderField: header.field) }
        // create the task
        let task = session.dataTask(with: request) { [weak self] (data, response, error) in
            // check error
            if let error = error { completion(.unknownError(error)); return }
            // check response for error
            if let responseError = self?.responseError(response, data: data) { completion(responseError); return }
            // all good return nil
            completion(nil)
        }
        // start the task
        task.resume()
    }
    
    #warning("Need to finish configuring web socket api")
    public func webSocket(scheme: String = "ws", path: String, queryItems: [URLQueryItem]? = nil){
        
    }
    
    private func responseError(_ response: URLResponse?, data: Data?) -> HttpError? {
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
    
    private func decodeData<Value: Decodable>(data: Data?) -> Value? {
        // check for data
        guard let data = data else { return nil }
        // try to decode the data
        do {
            let value = try JSONDecoder().decode(Value.self, from: data)
            // return value
            return value
        } catch {
            print(error); return nil
        }
    }
}
