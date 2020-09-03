//
//  Service.swift
//  Network
//
//  Created by Marcio Garcia on 06/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

import Foundation

public enum NetworkError<T>: Error, CustomStringConvertible {
    case badRequest(Int, T)
    case invalidRsponse(URLResponse?, T)
    case unableToDecode(Int, Data, T)
    case error(Int, T)

    public var description: String {
        switch self {
        case .badRequest:       return "Invalid request"
        case .invalidRsponse:   return "The request returned an invalid response."
        case .unableToDecode:   return "The response data could not be decoded."
        case .error:            return "Request error."
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

    private var tasks = NSCache<NSString, URLSessionTask>()
    private var debugMode = false
    private let requestBuilder: RequestBuildable
    private let logger: Logging

    init(debugMode: Bool = false, requestBuilder: RequestBuilder, logger: Logging) {
        self.debugMode = debugMode
        self.requestBuilder = requestBuilder
        self.logger = logger
    }

    func cancel(taskId: TaskId) {
        if let task = tasks.object(forKey: taskId.uuidString as NSString) {
            task.cancel()
            tasks.removeObject(forKey: taskId.uuidString as NSString)
        }
    }

    func request<T: NetworkRequest>(_ networkRequest: T,
                                    completion: @escaping (Result<Response<T.ModelType>, Error>) -> Void) -> TaskId {

        let session = URLSession.shared
        let taskId: TaskId = UUID()

        guard let request = self.requestBuilder.build(from: networkRequest) else {
            completion(.failure(NetworkError.badRequest(0, networkRequest)))
            return TaskId()
        }

        let task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in

            if self?.debugMode ?? false {
                self?.logger.logResponse(response: response, data: data)
            }

            self?.tasks.removeObject(forKey: taskId.uuidString as NSString)

            do {
                if let error = error { throw error }
                guard let resp = response as? HTTPURLResponse else { throw NetworkError.invalidRsponse(response, request) }

                if resp.statusCode > 299 {
                    guard let errorData = data else {
                        throw NetworkError.error(resp.statusCode, request)
                    }
                    guard let parsedErrorData = networkRequest.parseError(data: errorData) else {
                        throw NetworkError.unableToDecode(resp.statusCode, errorData, request)
                    }
                    throw NetworkError.error(resp.statusCode, parsedErrorData)
                }

                guard let responseData = data else {
                    completion(.success(Response<T.ModelType>(statusCode: resp.statusCode, value: nil)))
                    return
                }

                guard let parsedData = networkRequest.parse(data: responseData) else {
                    completion(.failure(NetworkError.unableToDecode(resp.statusCode, responseData, request)))
                    return
                }

                completion(.success(Response<T.ModelType>(statusCode: resp.statusCode, value: parsedData)))

            } catch let error {
                completion(.failure(error))
            }
        })
        tasks.setObject(task, forKey: taskId.uuidString as NSString)
        task.resume()
        return taskId
    }

    func request(with url: URL, completion: @escaping (Result<Response<Data>, Error>) -> Void) -> TaskId {

        let session = URLSession.shared
        let taskId: TaskId = UUID()
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            if self?.debugMode ?? false {
                self?.logger.logResponse(response: response, data: data)
            }

            self?.tasks.removeObject(forKey: taskId.uuidString as NSString)

            do {
                if let error = error { throw error }
                guard let resp = response as? HTTPURLResponse else { throw NetworkError.invalidRsponse(response, url) }

                if resp.statusCode > 299 {
                    throw NetworkError.error(resp.statusCode, data)
                }

                guard let responseData = data else {
                    completion(.success(Response<Data>(statusCode: resp.statusCode, value: nil)))
                    return
                }

                completion(.success(Response(statusCode: resp.statusCode, value: responseData)))
            } catch let error {
                completion(.failure(error))
            }
        }
        tasks.setObject(task, forKey: taskId.uuidString as NSString)
        task.resume()
        return taskId
    }
}
