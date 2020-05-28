//
//  Ivorywhite.swift
//  Ivorywhite
//
//  Created by Marcio Garcia on 28/05/20.
//  Copyright © 2020 Oxl Tech. All rights reserved.
//

public final class Ivorywhite {
    
    static var networkService: NetworkService?
    
    private init() {}
    
    public static func service(debugMode: Bool) -> NetworkService {
        if let networkService = self.networkService {
            return networkService
        } else {
            networkService = Service(debugMode: debugMode)
            return networkService!
        }
    }
}
