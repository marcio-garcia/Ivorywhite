//
//  Logging.swift
//  Ivorywhite
//
//  Created by Marcio Garcia on 16/06/20.
//  Copyright © 2020 Oxl Tech. All rights reserved.
//

import Foundation

public protocol Logging {
    func logRequest<T: NetworkRequest>(route: T, request: URLRequest)
    func logResponse(response: URLResponse?, data: Data?)
}
