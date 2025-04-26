//
//  Logger.swift
//  Ivorywhite
//
//  Created by Marcio Garcia on 16/06/20.
//  Copyright © 2020 Oxl Tech. All rights reserved.
//

import Foundation

class Logger {

    func logRequest(request: any Request) {
        print("-------------- Request --------------")
        print("Method: \(request.method.rawValue)")
//        print("BaseURL: \(.baseURL!.absoluteString)")
        print("Path: \(request.path)")
        print("Headers: \(request.headers?.description ?? "nil")")
        print("Parameters: \(request.queryParameters?.description ?? "nil")")
        print("Body: \(request.body?.description ?? "nil")")
    }

    func logResponse(data: Data) {
        let response = String(data: data, encoding: .utf8)
        print("Response: \(response ?? "nil")")
    }
}
