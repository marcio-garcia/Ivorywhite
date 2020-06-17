//
//  EndPointType.swift
//  Network
//
//  Created by Marcio Garcia on 06/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

public protocol NetworkRequest {
    associatedtype ModelType: Decodable
    associatedtype ErrorModelType: Decodable
    var baseURL: URL { get set }
    var path: String { get set }
    var httpMethod: HTTPMethod { get set }
    var httpHeaders: HTTPHeader? { get set }
    var parameters: Parameters? { get set }
    var encoding: ParameterEncoding? { get set }
    var timeoutInterval: TimeInterval { get set }
    func parse(data: Data) -> ModelType?
    func parseError(data: Data) -> ErrorModelType?
}
