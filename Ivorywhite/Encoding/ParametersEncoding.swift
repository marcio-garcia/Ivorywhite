//
//  ParametersEncoding.swift
//  Network
//
//  Created by Marcio Garcia on 06/06/19.
//  Copyright © 2019 Marcio Garcia. All rights reserved.
//

public typealias Parameters = [String:Any]

public enum ParameterEncoding {
    case jsonEncoding
    case urlEnconding
}

public protocol ParameterEncoder {
    static func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws
}

public enum EncodingError: String, Error {
    case parameterNil   = "Parameters wew nil."
    case encodingFailed = "Parameter encoding failed."
    case missingURL     = "URL is nil."
}
