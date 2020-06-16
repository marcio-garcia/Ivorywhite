//
//  Ivorywhite.swift
//  Ivorywhite
//
//  Created by Marcio Garcia on 28/05/20.
//  Copyright © 2020 Oxl Tech. All rights reserved.
//

public final class Ivorywhite {
    
    public static var shared = Ivorywhite()
    
    private var networkService: NetworkService?
    private var logger: Logging?
    private var requestBuilder: RequestBuilder?
    
    private init() {}
    
    public func service(debugMode: Bool) -> NetworkService {
        if let networkService = self.networkService {
            return networkService
        } else {
            logger = Logger()
            requestBuilder = RequestBuilder()
            networkService = Service(debugMode: debugMode,
                                     requestBuilder: requestBuilder!,
                                     logger: logger!)
            return networkService!
        }
    }
}
