//
//  Service.swift
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

    private var tasks: [TaskId: URLSessionTask] = [:]
    private var debugMode = false
    private let requestBuilder: RequestBuildable
    private let logger: Logging

    init(debugMode: Bool = false, requestBuilder: RequestBuilder, logger: Logging) {
        self.debugMode = debugMode
        self.requestBuilder = requestBuilder
        self.logger = logger
    }

    func cancel(taskId: TaskId) {
        if let task = tasks[taskId] {
            task.cancel()
            tasks.removeValue(forKey: taskId)
        }
    }

    func request<T: NetworkRequest>(_ networkRequest: T,
                                           completion: @escaping (Result<Response<T.ModelType>, Error>) -> Void) -> TaskId {

        let session = URLSession.shared
        let taskId: TaskId = UUID()
        do {
            let request = try self.requestBuilder.build(from: networkRequest)
            let task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in

                if self?.debugMode ?? false {
                    self?.logger.logResponse(response: response, data: data)
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

        let session = URLSession.shared
        let taskId: TaskId = UUID()
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            if self?.debugMode ?? false {
                self?.logger.logResponse(response: response, data: data)
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
}
