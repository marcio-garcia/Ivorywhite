//
//  Service.swift
//  Network
//
//  Created by Marcio Garcia on 06/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

import Foundation

public enum NetworkError<T>: Error, CustomStringConvertible {
    case badRequest(T)
    case invalidRsponse(URLResponse?, T)
    case unableToDecode(Data, T)
    case error(T)

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

    func request(_ networkRequest: NetworkRequest,
                 model: ResponseModel,
                 errorModel: ResponseModel,
                 completion: @escaping (Response) -> Void) -> TaskId {

        let session = URLSession.shared
        let taskId: TaskId = UUID()

        guard let request = self.requestBuilder.build(from: networkRequest) else {
            completion(Response(statusCode: 0, result: .failure(NetworkError.badRequest(networkRequest))))
            return TaskId()
        }

        let task = session.dataTask(with: request, completionHandler: { [unowned self] (data, response, error) in
            if self.debugMode {
                self.logger.logResponse(response: response, data: data)
            }

            self.tasks.removeObject(forKey: taskId.uuidString as NSString)

            if let error = error {
                completion(Response(statusCode: 500, result: .failure(error)))
                return
            }

            let response = self.createResponse(request: request,
                                               response: response,
                                               data: data,
                                               model: model,
                                               errorModel: errorModel)
            completion(response)
        })
        tasks.setObject(task, forKey: taskId.uuidString as NSString)
        task.resume()
        return taskId
    }

    func request(with url: URL, completion: @escaping (ResponseData) -> Void) -> TaskId {

        let session = URLSession.shared
        let taskId: TaskId = UUID()
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            if self?.debugMode ?? false {
                self?.logger.logResponse(response: response, data: data)
            }

            self?.tasks.removeObject(forKey: taskId.uuidString as NSString)

            if let error = error {
                let response = ResponseData(statusCode: 500, result: .failure(error))
                completion(response)
                return
            }

            guard let resp = response as? HTTPURLResponse else {
                let response = ResponseData(statusCode: 500,
                                            result: .failure(NetworkError.invalidRsponse(response, url)))
                completion(response)
                return
            }

            if resp.statusCode > 299 {
                let response = ResponseData(statusCode: resp.statusCode, result: .failure(NetworkError.error(data)))
                completion(response)
                return
            }

            guard let responseData = data else {
                let response = ResponseData(statusCode: resp.statusCode, result: .success(nil))
                completion(response)
                return
            }

            let response = ResponseData(statusCode: resp.statusCode, result: .success(responseData))
            completion(response)
        }
        tasks.setObject(task, forKey: taskId.uuidString as NSString)
        task.resume()
        return taskId
    }

    private func createResponse(request: URLRequest,
                                response: URLResponse?,
                                data: Data?,
                                model: ResponseModel,
                                errorModel: ResponseModel) -> Response {
        guard let resp = response as? HTTPURLResponse else {
            return Response(statusCode: 500,
                            result: .failure(NetworkError.invalidRsponse(response, request)))
        }

        if resp.statusCode > 299 {
            guard let errorData = data else {
                return Response(statusCode: resp.statusCode, result: .failure(NetworkError.error(request)))
            }

            guard let parsedErrorData = errorModel.parse(data: errorData) else {
                return Response(statusCode: resp.statusCode,
                                result: .failure(NetworkError.unableToDecode(errorData, request)))
            }

            return Response(statusCode: resp.statusCode,
                            result: .failure(NetworkError.error(parsedErrorData)))
        }

        guard let responseData = data else {
            return Response(statusCode: resp.statusCode, result: .success(nil))
        }

        guard let parsedData = model.parse(data: responseData) else {
            return Response(statusCode: resp.statusCode,
                            result: .failure(NetworkError.unableToDecode(responseData, request)))
        }

        return Response(statusCode: resp.statusCode, result: .success(parsedData))
    }
}
