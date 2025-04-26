//
//  NetworkInterceptor.swift
//  Ivorywhite
//
//  Created by Marcio Garcia on 4/26/25.
//

import Foundation

/// Interceptor for modifying requests or handling responses
public protocol NetworkInterceptor {
    /// Called before a request is sent
    func adapt(request: URLRequest) -> URLRequest

    /// Called after a response is received
    func intercept(response: HTTPURLResponse, data: Data)
}
