//
//  RequestBuildable.swift
//  Ivorywhite
//
//  Created by Marcio Garcia on 16/06/20.
//  Copyright © 2020 Oxl Tech. All rights reserved.
//

public protocol RequestBuildable {
    func build<T: NetworkRequest>(from route: T) throws -> URLRequest
}
