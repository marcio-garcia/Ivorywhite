//
//  File.swift
//  
//
//  Created by Marcio Garcia on 14/04/21.
//

import Foundation

public struct NetworkError: LocalizedError {
    /// A localized message describing what error occurred.
    public var errorDescription: String?
    /// A localized message describing the reason for the failure.
    public var failureReason: String?
    /// A localized message describing how one might recover from the failure.
    public var recoverySuggestion: String?
    /// A localized message providing "help" text if the user requests help.
    public var helpAnchor: String?

    static func invalidRequest(request: NetworkRequest) -> NetworkError {
        let errorDescription = "Ivorywhite: Invalid request!"
        let baseURL = String(describing: request.baseURL)
        let httpHeaders = String(describing: request.httpHeaders)
        let parameters = String(describing: request.parameters)
        let encoding = String(describing: request.encoding)
        let failureReason = "Ivorywhite: could not build the request with the following data - httpMethod=\(request.httpMethod); baseURL=\(baseURL); path=\(request.path) httpHeaders=\(httpHeaders); parameters=\(parameters); encoding=\(encoding)"
        return NetworkError(errorDescription: errorDescription, failureReason: failureReason, recoverySuggestion: nil, helpAnchor: nil)
    }

    static func invalidResponse(response: URLResponse?) -> NetworkError {
        let errorDescription = "Ivorywhite: Invalid response!"
        let failureReason = "Ivorywhite: the request returned an invalid response. \(String(describing: response?.debugDescription))"
        return NetworkError(errorDescription: errorDescription, failureReason: failureReason, recoverySuggestion: nil, helpAnchor: nil)
    }

    static func networkError(statusCode: Int) -> NetworkError {
        return NetworkError(errorDescription: "Ivorywhite: Network error.",
                            failureReason: "Internal server error. status code: \(statusCode)",
                            recoverySuggestion: nil,
                            helpAnchor: nil)
    }

    static func unableToDecode(data: Data) -> NetworkError {
        let string = String(describing: String(data: data, encoding: .utf8))
        return NetworkError(errorDescription: "Ivorywhite: Unable to decode response.", failureReason: "Ivorywhite: the parser implementation provided by the caller was not able to decode the data returned in the response body. Printing the string representation of the response body: \(string)", recoverySuggestion: nil, helpAnchor: nil)
    }
}
