//
//  RequestBuilder.swift
//  Ivorywhite
//
//  Created by Marcio Garcia on 16/06/20.
//  Copyright © 2020 Oxl Tech. All rights reserved.
//

import Foundation

class RequestBuilder: RequestBuildable {
    func build(from route: NetworkRequest) -> URLRequest? {

        guard let url = buildUrl(from: route) else {
            return nil
        }

        var httpBody: Data?
        if let parameters = route.parameters, let enconding = route.encoding, enconding == .jsonEncoding {
            httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: .fragmentsAllowed)
        }

        var request = URLRequest(url: url,
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: route.timeoutInterval)

        request.httpMethod = route.httpMethod.rawValue
        request.httpBody = httpBody

        if let headers = route.httpHeaders {
            addAdditionalHeaders(headers, route: route, request: &request)
        }

        return request
    }

    private func buildUrl(from route: NetworkRequest) -> URL? {

        var urlComponents = URLComponents()
        var baseURL = route.baseURL.absoluteString
        var scheme = "http"

        if baseURL.contains("https") {
            scheme = "https"
        }

        baseURL = baseURL.replacingOccurrences(of: "\(scheme)://", with: "")

        urlComponents.scheme = scheme
        urlComponents.host = baseURL
        urlComponents.path = route.path

        if let parameters = route.parameters, let encoding = route.encoding, encoding == .urlEnconding {
            var queryItems = [URLQueryItem]()

            for (key, value) in parameters {
                let queryItem = URLQueryItem(name: key, value: "\(value)")
                queryItems.append(queryItem)
            }
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            debugPrint("Ivorywhite error: Could not build URL")
            debugPrint("Ivorywhite error: \(urlComponents.debugDescription)")
            return nil
        }

        return url
    }

    private func addAdditionalHeaders(_ additionalHeaders: HTTPHeader?,
                                      route: NetworkRequest,
                                      request: inout URLRequest) {

        if let encoding = route.encoding, encoding == .urlEnconding {
            if request.value(forHTTPHeaderField: HTTPHeaderFields.contentType.rawValue) == nil {
                switch encoding {
                case .jsonEncoding:
                    request.setValue("application/json",
                                     forHTTPHeaderField: HTTPHeaderFields.contentType.rawValue)
                case .urlEnconding:
                    request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                                     forHTTPHeaderField: HTTPHeaderFields.contentType.rawValue)
                }
            }
        }

        guard let headers = additionalHeaders else { return }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
}
