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
    func request<T: NetworkRequest>(_ networkRequest: T, completion: @escaping (Result<Response<T.ModelType>, Error>)->Void) -> TaskId
    func cancel(taskId: TaskId)
}
