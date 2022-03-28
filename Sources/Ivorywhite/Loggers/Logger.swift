//
//  Logger.swift
//  Ivorywhite
//
//  Created by Marcio Garcia on 16/06/20.
//  Copyright © 2020 Oxl Tech. All rights reserved.
//

import Foundation

class Logger: Logging {

    func logRequest(route: NetworkRequest, request: URLRequest) {
        print("-------------- Request --------------")
        print("Method: \(route.httpMethod.rawValue)")
        print("BaseURL: \(route.baseURL!.absoluteString)")
        print("Path: \(route.path)")
        print("Headers: \(request.allHTTPHeaderFields?.description ?? "nil")")
        print("Parameters: \(route.parameters?.description ?? "nil")")
        print("Request: \(request.debugDescription)")
        if let body = request.httpBody {
            let httpBodyString = String(data: body, encoding: .utf8)!
            print("Body: \(httpBodyString)")
        }
    }

    func logResponse(response: URLResponse?, data: Data?) {
        guard let resp = response else { return }
        print("Response: \(resp.debugDescription)")
        guard let data = data, let dataString = String(data: data, encoding: .utf8) else { return }
        print(dataString)
    }
}
