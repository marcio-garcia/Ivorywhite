//
//  NetworkRouter.swift
//  Network
//
//  Created by Marcio Garcia on 06/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

import Foundation

public typealias TaskId = UUID

public protocol NetworkService {
    func request(_ networkRequest: NetworkRequest,
                 model: ResponseModel,
                 errorModel: ErrorResponseModel,
                 completion: @escaping (Response) -> Void) -> TaskId
    func request(with url: URL, completion: @escaping (ResponseData) -> Void) -> TaskId
    func cancel(taskId: TaskId)
}

public struct Response {
    public var statusCode: Int
    public var result: Result<ResponseModel?, Error>
}

public struct ResponseData {
    public var statusCode: Int
    public var result: Result<Data?, Error>
}
