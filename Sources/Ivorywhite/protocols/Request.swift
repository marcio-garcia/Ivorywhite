//
//  Request.swift
//  Network
//
//  Created by Marcio Garcia on 06/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

import Foundation

public protocol Request {
    /// The type of the response model for this request
    associatedtype Response: Decodable

    /// The endpoint path, e.g. "/users"
    var path: String { get }

    /// HTTP method to use
    var method: HTTPMethod { get }

    /// Query parameters to append to URL
    var queryParameters: [String: String]? { get }

    /// HTTP headers
    var headers: [String: String]? { get }

    /// Body dictionary for methods like POST/PUT
    var body: [String: Any]? { get }
}

