//
//  Router.swift
//  Network
//
//  Created by Marcio Garcia on 06/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

public enum NetworkError: String, Error {
    case authenticationError    = "You need to be authenticated first."
    case badRequest             = "Bad request."
    case outdated               = "The url you requested is outdated."
    case failed                 = "The network request failed."
    case noData                 = "Response returned with no data to decode."
    case unableToDecode         = "We could not decode the response."
}

//private class StatusCode {
//    func handle(_ response: HTTPURLResponse) -> Result<Int?, NetworkError> {
//        switch response.statusCode {
//        case 200...299: return .success(nil)
//        case 401...499: return .failure(.authenticationError)
//        case 500...599: return .failure(.badRequest)
//        case 600:       return .failure(.outdated)
//        default:        return .failure(.failed)
//        }
//    }
//}

public class Service: NetworkService {

    private var tasks: [TaskId: URLSessionTask] = [:]
    
    public init() {}
    
    public func request<T: NetworkRequest>(_ networkRequest: T,
                                           completion: @escaping (Result<T.ModelType, Error>)->Void) -> TaskId {
        let session = URLSession.shared
        let taskId: TaskId = UUID()
        do {
            let request = try self.buildUrlRequest(from: networkRequest)
            let task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
                completion(Result{
                    self?.tasks.removeValue(forKey: taskId)
                    if let e = error { throw e }
                    guard let responseData = data else { throw NetworkError.noData }
                    return try networkRequest.parse(data: responseData)
                })
            })
            tasks[taskId] = task
            task.resume()
            return taskId
        } catch {
            completion(.failure(NetworkError.badRequest))
        }
        return UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
    
    public func cancel(taskId: TaskId) {
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
}
