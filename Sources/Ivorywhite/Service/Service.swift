//
//  Service.swift
//  Network
//
//  Created by Marcio Garcia on 06/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

import Foundation

public struct NetworkError: LocalizedError {
    public var errorDescription: String? {
        return _localizedDescription
    }

    private var _localizedDescription: String = ""

    public init(localizedDescription: String) {
        self._localizedDescription = localizedDescription
    }
}

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
            completion(Response(statusCode: 0, result: .failure(NetworkError(localizedDescription: "Ivorywhite: Invalid request!"))))
            return ""
        }

        if configuration.debugMode {
            configuration.logger?.logRequest(route: networkRequest, request: request)
        }

        let task = session.dataTask(with: request, completionHandler: { [unowned self] (data, response, error) in
            if configuration.debugMode {
                configuration.logger?.logResponse(response: response, data: data)
            }

            tasks.removeObject(forKey: taskId as NSString)

            if let error = error {
                completion(Response(statusCode: 500, result: .failure(error)))
                return
            }

            let response = createResponse(request: request,
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
                                            result: .failure(NetworkError(localizedDescription: "Ivorywhite: Invalid response!")))
                completion(response)
                return
            }

            if resp.statusCode > 299 {
                let response = ResponseData(statusCode: resp.statusCode, result: .failure(NetworkError(localizedDescription: "Ivorywhite: Network error.")))
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
                            result: .failure(NetworkError(localizedDescription: "Ivorywhite: Invalid response!")))
        }

        if resp.statusCode > 299 {
            guard let errorData = data else {
                return Response(statusCode: resp.statusCode, result: .failure(NetworkError(localizedDescription: "Ivorywhite: Network error.")))
            }

            guard let parsedErrorData = errorModel.parse(data: errorData) else {
                return Response(statusCode: resp.statusCode,
                                result: .failure(NetworkError(localizedDescription: "Ivorywhite: Unable to decode response.")))
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
            return Response(statusCode: resp.statusCode,
                            result: .failure(NetworkError(localizedDescription: "Ivorywhite: Unable to decode response.")))
        }

        return Response(statusCode: resp.statusCode, result: .success(parsedData))
    }
}
