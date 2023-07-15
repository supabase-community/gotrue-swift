import Foundation

extension URLRequest {
  init(
    baseURL: URL,
    path: String,
    method: String,
    query: [URLQueryItem],
    headers: [String: String],
    body: Data?
  ) throws {
    var url = baseURL.appendingPathComponent(path)
    if !query.isEmpty {
      guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        throw URLError(.badURL)
      }

      components.queryItems = query

      if let newURL = components.url {
        url = newURL
      } else {
        throw URLError(.badURL)
      }
    }

    var request = URLRequest(url: url)
    request.httpMethod = method
    request.httpBody = body

    for (name, value) in headers {
      request.setValue(value, forHTTPHeaderField: name)
    }

    self = request
  }
}
