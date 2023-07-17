import Foundation

struct Request {
  var path: String
  var method: String
  var query: [URLQueryItem] = []
  var headers: [String: String] = [:]
  var body: Data?

  func urlRequest(withBaseURL baseURL: URL) throws -> URLRequest {
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

    return request
  }
}

struct Response {
  let data: Data
  let response: HTTPURLResponse

  func decoded<T: Decodable>(as _: T.Type, decoder: JSONDecoder) throws -> T {
    try decoder.decode(T.self, from: data)
  }
}
