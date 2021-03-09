//
//  NetworkRouter.swift
//  Network
//
//  Created by Marcio Garcia on 06/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

import Foundation

public protocol NetworkService {
    func request(_ networkRequest: NetworkRequest,
                 model: ResponseModel,
                 errorModel: ErrorResponseModel,
                 completion: @escaping (Response) -> Void) -> String
    func request(with url: URL, completion: @escaping (ResponseData) -> Void) -> String
    func cancel(taskId: String)
}

public struct Response {
    public var statusCode: Int
    public var result: Result<ResponseModel?, Error>
}

public struct ResponseData {
    public var statusCode: Int
    public var result: Result<Data?, Error>
}
