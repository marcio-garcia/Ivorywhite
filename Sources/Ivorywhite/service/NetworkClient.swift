//
//  NetworkClient.swift
//  Ivorywhite
//
//  Created by Marcio Garcia on 4/26/25.
//

import Foundation

/// Core network client for IvoryWhite
public final class NetworkClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let interceptors: [NetworkInterceptor]

    /// Initialize the network client
    /// - Parameters:
    ///   - baseURL: Base URL of the API
    ///   - session: URLSession instance (allows injection/testing)
    ///   - decoder: JSONDecoder for response parsing
    ///   - interceptors: Optional array of interceptors
    public init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        interceptors: [NetworkInterceptor] = []
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.interceptors = interceptors
    }

    /// Execute a request with cancellation support
    /// - Parameter request: Conforming to `Request`
    /// - Returns: A `Task` you can await or cancel
    @discardableResult
    public func request<R: Request>(_ request: R) -> Task<R.Response, Error> {
        return Task {
            var urlRequest = try buildURLRequest(from: request)

            // Adapt request via interceptors
            urlRequest = interceptors.reduce(urlRequest) { req, interceptor in
                interceptor.adapt(request: req)
            }

            // Perform network call
            let (data, response) = try await session.data(for: urlRequest)

            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // Intercept response via interceptors
            interceptors.forEach { $0.intercept(response: httpResponse, data: data) }

            // Decode and return
            return try decoder.decode(R.Response.self, from: data)
        }
    }

    /// Build a URLRequest from a Request type
    private func buildURLRequest<R: Request>(from request: R) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }

        // Attach query parameters
        if let queries = request.queryParameters {
            components.queryItems = queries.map { URLQueryItem(name: $0, value: $1) }
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue

        // Encode and set body if present
        if let bodyDict = request.body {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // Set custom headers
        request.headers?.forEach { field, value in
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }
        return urlRequest
    }
}
