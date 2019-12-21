//
//  URLEncoder.swift
//  Network
//
//  Created by Marcio Garcia on 06/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

public struct URLEncoder: ParameterEncoder {
    public static func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws {
        guard let url = urlRequest.url else { throw EncodingError.missingURL }
        
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
            
            urlComponents.queryItems = [URLQueryItem]()
            
            for (key, value) in parameters {
                let queryItem = URLQueryItem(name: key, value: "\(value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))
                
                urlComponents.queryItems?.append(queryItem)
            }
            urlRequest.url = urlComponents.url
        }
        
        if urlRequest.value(forHTTPHeaderField: HTTPHeaderFields.contentType.rawValue) == nil {
            urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: HTTPHeaderFields.contentType.rawValue)
        }
    }
}
