//
//  File.swift
//  
//
//  Created by Marcio Garcia on 08/03/21.
//

import Foundation

public struct NetworkConfiguration {
    public var debugMode: Bool
    public var logger: Logging?
    public var requestBuilder: RequestBuildable?

    public init(debugMode: Bool) {
        self.debugMode = debugMode
    }
}
