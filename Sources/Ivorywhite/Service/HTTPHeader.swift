//
//  HTTPHeader.swift
//  NetworkLayer
//
//  Created by Marcio Garcia on 07/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

public typealias HTTPHeader = [String: String]

enum HTTPHeaderFields: String {
    case contentType = "Content-Type"
}
