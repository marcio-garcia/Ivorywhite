//
//  Router.swift
//  Network
//
//  Created by Marcio Garcia on 06/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

import Foundation

public enum NetworkError: Error, CustomStringConvertible {
    case authenticationError
    case badRequest
    case outdated
    case failed
    case noData
    case unableToDecode

    public var description: String {
        switch self {
        case .authenticationError:  return "You need to be authenticated first."
        case .badRequest:           return "Bad request."
        case .outdated:             return "The url you requested is outdated."
        case .failed:               return "The network request failed."
        case .noData:               return "Response returned with no data to decode."
        case .unableToDecode:       return "We could not decode the response."
        }
    }

    public var localizedDescription: String {
        return self.description
    }
}

public struct Response<T> {
    public var statusCode: Int
    public var value: T?
}

class Service: NetworkService {

    private var urlSession: URLSession
    private var tasks: [TaskId: URLSessionTask] = [:]
    private var debugMode = false
    private var timeoutIntervalForRequest: TimeInterval

    init(debugMode: Bool = false, timeoutIntervalForRequest: TimeInterval = 60.0) {
        self.debugMode = debugMode
        self.timeoutIntervalForRequest = timeoutIntervalForRequest
        let config = URLSessionConfiguration()
        config.timeoutIntervalForRequest = timeoutIntervalForRequest
        self.urlSession = URLSession(configuration: config)
    }
    
    func request<T: NetworkRequest>(_ networkRequest: T,
                                           completion: @escaping (Result<Response<T.ModelType>, Error>) -> Void) -> TaskId {

        let session = urlSession
        let taskId: TaskId = UUID()
        do {
            let request = try self.buildUrlRequest(from: networkRequest)
            let task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in

                if self?.debugMode ?? false {
                    self?.logResponse(response: response, data: data)
                }

                self?.tasks.removeValue(forKey: taskId)

                do {
                    if let e = error { throw e }
                    guard let resp = response as? HTTPURLResponse else { throw NetworkError.failed }
                    guard let responseData = data else { throw NetworkError.noData }

                    if resp.statusCode > 299 { throw NetworkError.badRequest }

                    if let parsedData = try networkRequest.parse(data: responseData) {
                        completion(Result{
                            return Response<T.ModelType>(statusCode: resp.statusCode, value: parsedData)
                        })
                    } else {
                        completion(.failure(NetworkError.unableToDecode))
                    }
                } catch let error {
                    completion(.failure(error))
                }
            })
            tasks[taskId] = task
            task.resume()
            return taskId
        } catch {
            debugPrint("Ivorywhite: Request error: \(error.localizedDescription)")
            completion(.failure(NetworkError.badRequest))
        }
        return UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }

    func request(with url: URL, completion: @escaping (Result<Response<Data>, Error>) -> Void) -> TaskId {

        let session = urlSession
        let taskId: TaskId = UUID()
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            if self?.debugMode ?? false {
                self?.logResponse(response: response, data: data)
            }

            self?.tasks.removeValue(forKey: taskId)

            do {
                if let e = error { throw e }
                guard let resp = response as? HTTPURLResponse else { throw NetworkError.failed }
                guard let responseData = data else { throw NetworkError.noData }

                if resp.statusCode > 299 { throw NetworkError.badRequest }

                completion(.success(Response<Data>(statusCode: resp.statusCode, value: responseData)))
            } catch let error {
                completion(.failure(error))
            }
        }
        tasks[taskId] = task
        task.resume()
        return taskId
    }

    func cancel(taskId: TaskId) {
        if let task = tasks[taskId] {
            task.cancel()
            tasks.removeValue(forKey: taskId)
        }
    }
    
    private func buildUrlRequest<T: NetworkRequest>(from route: T) throws -> URLRequest {

        var request = URLRequest(url: route.baseURL.appendingPathComponent(route.path),
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 10.0)
        
        request.httpMethod = route.httpMethod.rawValue

        if let headers = route.httpHeaders {
            addAdditionalHeaders(headers, request: &request)
        }

        if let parameters = route.parameters {
            do {
                try configureParameters(parameters: parameters,
                                        encoding: route.encoding,
                                        request: &request)
            } catch {
                throw error
            }
        }

        if debugMode {
            logRequest(route: route, request: request)
        }
        
        return request
    }

    private func configureParameters(parameters: Parameters,
                                     encoding: ParameterEncoding?,
                                     request: inout URLRequest) throws {
        
        do {
            guard let encoding = encoding else {
                try JSONEncoder.encode(urlRequest: &request, with: parameters)
                return
            }
            
            switch encoding {
            case .jsonEncoding:
                try JSONEncoder.encode(urlRequest: &request, with: parameters)
            case .urlEnconding:
                try URLEncoder.encode(urlRequest: &request, with: parameters)
            }
        } catch {
            throw error
        }
    }
    
    private func addAdditionalHeaders(_ additionalHeaders: HTTPHeader?, request: inout URLRequest) {
        guard let headers = additionalHeaders else { return }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    private func logRequest<T: NetworkRequest>(route: T, request: URLRequest) {
        print("-------------- Request --------------")
        print("Method: \(route.httpMethod.rawValue)")
        print("BaseURL: \(route.baseURL)")
        print("Path: \(route.path)")
        print("Headers: \(request.allHTTPHeaderFields?.description ?? "nil")")
        print("Parameters: \(route.parameters?.description ?? "nil")")
        print("Request: \(request.debugDescription)")
        if let body = request.httpBody {
            let httpBodyString = String(data: body, encoding: .utf8)!
            print("Body: \(httpBodyString)")
        }
    }

    private func logResponse(response: URLResponse?, data: Data?) {
        guard let resp = response else { return }
        print("Response: \(resp.debugDescription)")
        guard let data = data, let dataString = String(data: data, encoding: .utf8) else { return }
        print(dataString)
    }
}
