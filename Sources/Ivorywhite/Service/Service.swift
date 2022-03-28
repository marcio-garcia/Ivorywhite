//
//  Service.swift
//  Network
//
//  Created by Marcio Garcia on 06/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

import Foundation

class Service: NetworkService {

    private var tasks = NSCache<NSString, URLSessionTask>()
    private var configuration: NetworkConfiguration

    init(configuration: NetworkConfiguration) {
        self.configuration = configuration
    }

    func cancel(taskId: String) {
        if let task = tasks.object(forKey: taskId as NSString) {
            task.cancel()
            tasks.removeObject(forKey: taskId as NSString)
        }
    }

    func request(_ networkRequest: NetworkRequest,
                 model: ResponseModel.Type? = nil,
                 errorModel: ErrorResponseModel.Type,
                 completion: @escaping (Response) -> Void) -> String {

        let session = URLSession.shared
        let taskId: String = UUID().uuidString

        guard let request = configuration.requestBuilder?.build(from: networkRequest) else {
            debugPrint(networkRequest)
            completion(Response(statusCode: 0, result: .failure(NetworkError.invalidRequest(request: networkRequest))))
            return ""
        }

        if configuration.debugMode {
            configuration.logger?.logRequest(route: networkRequest, request: request)
        }

        let task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let strongSelf = self else {
                let error = NSError(domain: "Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
                let response = Response(statusCode: 500, result: .failure(error))
                completion(response)
                return
            }

            if strongSelf.configuration.debugMode {
                strongSelf.configuration.logger?.logResponse(response: response, data: data)
            }

            strongSelf.tasks.removeObject(forKey: taskId as NSString)

            if let error = error {
                completion(Response(statusCode: 500, result: .failure(error)))
                return
            }

            let response = strongSelf.createResponse(request: request,
                                                     response: response,
                                                     data: data,
                                                     model: model,
                                                     errorModel: errorModel)
            completion(response)
        })
        tasks.setObject(task, forKey: taskId as NSString)
        task.resume()
        return taskId
    }

    func request(with url: URL, completion: @escaping (ResponseData) -> Void) -> String {

        let session = URLSession.shared
        let taskId: String = UUID().uuidString
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            if self?.configuration.debugMode ?? false {
                self?.configuration.logger?.logResponse(response: response, data: data)
            }

            self?.tasks.removeObject(forKey: taskId as NSString)

            if let error = error {
                let response = ResponseData(statusCode: 500, result: .failure(error))
                completion(response)
                return
            }

            guard let resp = response as? HTTPURLResponse else {
                let response = ResponseData(statusCode: 500,
                                            result: .failure(NetworkError.invalidResponse(response: response)))
                completion(response)
                return
            }

            if resp.statusCode > 299 {
                let response = ResponseData(statusCode: resp.statusCode, result: .failure(NetworkError.networkError(statusCode: resp.statusCode)))
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
        tasks.setObject(task, forKey: taskId as NSString)
        task.resume()
        return taskId
    }

    private func createResponse(request: URLRequest,
                                response: URLResponse?,
                                data: Data?,
                                model: ResponseModel.Type?,
                                errorModel: ErrorResponseModel.Type) -> Response {
        guard let resp = response as? HTTPURLResponse else {
            return Response(statusCode: 500,
                            result: .failure(NetworkError.invalidResponse(response: response)))
        }

        if resp.statusCode > 299 {
            guard let errorData = data else {
                return Response(statusCode: resp.statusCode, result: .failure(NetworkError.networkError(statusCode: resp.statusCode)))
            }

            guard let parsedErrorData = errorModel.parse(data: errorData) else {
                return Response(statusCode: resp.statusCode,
                                result: .failure(NetworkError.unableToDecode(data: errorData)))
            }

            return Response(statusCode: resp.statusCode, result: .failure(parsedErrorData))
        }

        guard let modelType = model else {
            return Response(statusCode: resp.statusCode, result: .success(nil))
        }

        guard let responseData = data else {
            return Response(statusCode: resp.statusCode, result: .success(nil))
        }

        guard let parsedData = modelType.parse(data: responseData) else {
            return Response(statusCode: resp.statusCode, result: .failure(NetworkError.unableToDecode(data: responseData)))
        }

        return Response(statusCode: resp.statusCode, result: .success(parsedData))
    }
}
