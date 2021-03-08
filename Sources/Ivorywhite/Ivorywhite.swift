//
//  Ivorywhite.swift
//  Ivorywhite
//
//  Created by Marcio Garcia on 28/05/20.
//  Copyright © 2020 Oxl Tech. All rights reserved.
//

public final class Ivorywhite {

    public static var shared = Ivorywhite()
    public var defaultService: NetworkService

    private init() {
        var configuration = NetworkConfiguration(debugMode: false)
        configuration.requestBuilder = RequestBuilder()
        configuration.logger = Logger()

        defaultService = Service(configuration: configuration)
    }

    public func service(configuration: NetworkConfiguration) -> NetworkService {
        let config = setDefaultHandlers(configuration: configuration)
        let networkService = Service(configuration: config)
        return networkService
    }

    private func setDefaultHandlers(configuration: NetworkConfiguration) -> NetworkConfiguration {
        var config = NetworkConfiguration(debugMode: configuration.debugMode)
        config.logger = configuration.logger ?? Logger()
        config.requestBuilder = configuration.requestBuilder ?? RequestBuilder()
        return config
    }
}
