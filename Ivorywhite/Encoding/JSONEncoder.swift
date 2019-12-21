//
//  JSONEncoder.swift
//  Network
//
//  Created by Marcio Garcia on 06/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

public struct JSONEncoder: ParameterEncoder {
    public static func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            urlRequest.httpBody = jsonData
            if urlRequest.value(forHTTPHeaderField: HTTPHeaderFields.contentType.rawValue) == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: HTTPHeaderFields.contentType.rawValue)
            }
        } catch {
            throw EncodingError.encodingFailed
        }
    }
}
