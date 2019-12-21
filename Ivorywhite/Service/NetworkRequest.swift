//
//  EndPointType.swift
//  Network
//
//  Created by Marcio Garcia on 06/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

public protocol NetworkRequest {
    associatedtype ModelType: Decodable
    var baseURL: URL { get set }
    var path: String { get set }
    var httpMethod: HTTPMethod { get set }
    var httpHeaders: HTTPHeader? { get set }
    var parameters: Parameters? { get set }
    var encoding: ParameterEncoding? { get set }
    func parse(data: Data) throws -> ModelType
}

//extension NetworkRequest where ModelType: Decodable {
//    public init(baseURL: URL,
//                            path: String,
//                            httpMethod: HTTPMethod,
//                            httpHeaders: HTTPHeader?,
//                            parameters: Parameters?,
//                            encoding: ParameterEncoding?) {
//
//        self.init(parse: { data in
//            try JSONDecoder().decode(ModelType.self, from: data)
//        })
//
//        self.baseURL = baseURL
//        self.path = path
//        self.httpMethod = httpMethod
//        self.httpHeaders = httpHeaders
//        self.parameters = parameters
//        self.encoding = encoding
//    }
//}

//extension NetworkRequest {
//    func parse(data: Data) throws -> ModelType {
//        try JSONDecoder().decode(ModelType.self, from: data)
//    }
//}
