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
    case urlError
}

public class NetworkService {
    // url scheme
    private let scheme : String
    // url host
    private let host : String
    // url port
    private let port : Int?
    // request headers
    private (set) var headers : [HttpHeader]
    // session dependency
    private let urlSession : URLSession
    // init
    public init(scheme: String = "http", host: String, port: Int? = nil, headers: [HttpHeader] = [], urlSession : URLSession = .lightWeight) {
        self.scheme = scheme
        self.host = host
        self.port = port
        self.headers = headers
        self.urlSession = urlSession
    }
    // web socket access
    private lazy var websocketService : WebSocketService = {
        WebSocketService(host: host, port: port, headers: headers)
    }()
}

// computed properties

extension NetworkService {
    var urlComponents : URLComponents {
        // create object
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        // return components
        return components
    }
}

// API

extension NetworkService {
    public func addHeader(_ header: HttpHeader){
        headers.append(header)
    }
    
    public func removeHeader(for field: String){
        headers = headers.filter { $0.field != field }
    }
}

// networking methods

extension NetworkService {
    public func get<Value: Decodable>(path: String, queryItems: [URLQueryItem]? = nil, completion: @escaping (Result<Value, HTTPError>) -> Void) {
        // pull in components
        var components = self.urlComponents
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
        urlSession.dataTask(with: request) { [weak self] (data, response, error) in
            // check for error
            if let error = error { completion(.failure(.unknownError(error))); return }
            // check response for error
            if let error = self?.responseError(response, data: data) { completion(.failure(error)); return }
            // check for data
            guard let data = data else { completion(.failure(.dataAbsentFromResponse)); return }
            // decode the data to object
            do {
                // decode data
                let value = try JSONDecoder().decode(Value.self, from: data)
                // send to completion
                completion(.success(value))
            } catch {
                print(error); completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
    
    public func post<Body: Encodable>(path: String, body: Body, completion: @escaping (HTTPError?) -> Void){
        // pull in components
        var components = self.urlComponents
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
        // add json header
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // create the task
        urlSession.dataTask(with: request) { [weak self] (data, response, error) in
            // check error
            if let error = error { completion(.unknownError(error)); return }
            // check response for error
            if let responseError = self?.responseError(response, data: data) { completion(responseError); return }
            // all good return nil
            completion(nil)
        }.resume()
    }
    
    public func put<Body: Encodable>(path: String, body: Body, completion: @escaping (HTTPError?) -> Void){
        // pull in components
        var components = self.urlComponents
        // add path
        components.path = path
        // check url
        guard let url = components.url else { completion(.urlError); return }
        // create request with url
        var request = URLRequest(url: url)
        // set method
        request.httpMethod = "Put"
        // set body data
        do { let data = try JSONEncoder().encode(body); request.httpBody = data } catch { print(error); completion(.encodingError(error)); return }
        // set headers
        headers.forEach { header in request.addValue(header.value, forHTTPHeaderField: header.field) }
        // add json header
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // create the task
        urlSession.dataTask(with: request) { [weak self] (data, response, error) in
            // check error
            if let error = error { completion(.unknownError(error)); return }
            // check response for error
            if let responseError = self?.responseError(response, data: data) { completion(responseError); return }
            // all good return nil
            completion(nil)
        }.resume()
    }
    
    public func delete(path: String, queryItems: [URLQueryItem]? = nil, completion: @escaping (HTTPError?) -> Void){
        // pull in components
        var components = self.urlComponents
        // add path
        components.path = path
        // add query items
        components.queryItems = queryItems
        // check url
        guard let url = components.url else { completion(.urlError); return }
        // create request with url
        var request = URLRequest(url: url)
        // set method
        request.httpMethod = "Delete"
        // set headers
        headers.forEach { header in request.addValue(header.value, forHTTPHeaderField: header.field) }
        // create the task
        urlSession.dataTask(with: request) { [weak self] (data, response, error) in
            // check error
            if let error = error { completion(.unknownError(error)); return }
            // check response for error
            if let responseError = self?.responseError(response, data: data) { completion(responseError); return }
            // all good return nil
            completion(nil)
        }.resume()
    }
    
    public func listen<T: AnyObject, D: Decodable>(_ observer: T, channel: UUID, completion: @escaping (T, D) -> Void){
        websocketService.createListener(observer, channel: channel, completion: completion)
    }
}

// helper API

extension NetworkService {
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
            let value = try JSONDecoder().decode(Value.self, from: data)
            // return value
            return value
        } catch {
            print(error); return nil
        }
    }
}
