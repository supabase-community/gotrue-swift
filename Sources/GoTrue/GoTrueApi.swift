import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

class GoTrueApi {
  var url: String
  var headers: [String: String]

  init(url: String, headers: [String: String]) {
    self.url = url
    self.headers = headers
    self.headers.merge(GoTrueConstants.defaultHeaders) { $1 }
  }

  /// HTTP Methods
  private enum HTTPMethod: String {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case connect = "CONNECT"
    case options = "OPTIONS"
    case trace = "TRACE"
    case patch = "PATCH"
  }

  func signUpWithEmail(
    email: String, password: String, completion: @escaping (Result<User, Error>) -> Void
  ) {
    guard let url = URL(string: "\(url)/signup") else {
      completion(.failure(GoTrueError(message: "badURL")))
      return
    }

    fetch(url: url, method: .post, parameters: ["email": email, "password": password]) { result in
      let user = result.flatMap { data in
        Result { try decoder.decode(User.self, from: data) }
      }
      completion(user)
    }
  }

  func signInWithEmail(
    email: String, password: String, completion: @escaping (Result<Session, Error>) -> Void
  ) {
    guard let url = URL(string: "\(url)/token?grant_type=password") else {
      completion(.failure(GoTrueError(message: "badURL")))
      return
    }

    fetch(url: url, method: .post, parameters: ["email": email, "password": password]) { result in
      let session = result.flatMap { data in
        Result { try decoder.decode(Session.self, from: data) }
      }
      completion(session)
    }
  }

  func sendMagicLinkEmail(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
    guard let url = URL(string: "\(url)/magiclink") else {
      completion(.failure(GoTrueError(message: "badURL")))
      return
    }

    fetch(url: url, method: .post, parameters: ["email": email]) { result in
      completion(result.map { _ in () })
    }
  }

  func getUrlForProvider(provider: Provider, options: ProviderOptions?) throws -> URL {
    guard var components = URLComponents(string: "\(url)/authorize") else {
      throw GoTrueError(message: "badURL")
    }

    var queryItems: [URLQueryItem] = []
    queryItems.append(URLQueryItem(name: "provider", value: provider.rawValue))
    if let options = options {
      if let scopes = options.scopes {
        queryItems.append(URLQueryItem(name: "scopes", value: scopes))
      }
      if let redirectTo = options.redirectTo {
        queryItems.append(URLQueryItem(name: "redirect_to", value: redirectTo))
      }
    }

    components.queryItems = queryItems

    guard let url = components.url else {
      throw GoTrueError(message: "badURL")
    }

    return url
  }

  func refreshAccessToken(
    refreshToken: String, completion: @escaping (Result<Session, Error>) -> Void
  ) {
    guard let url = URL(string: "\(url)/token?grant_type=refresh_token") else {
      completion(.failure(GoTrueError(message: "badURL")))
      return
    }

    fetch(url: url, method: .post, parameters: ["refresh_token": refreshToken]) { result in
      let session = result.flatMap { data in
        Result { try decoder.decode(Session.self, from: data) }
      }
      completion(session)
    }
  }

  func signOut(accessToken: String, completion: @escaping (Error?) -> Void) {
    guard let url = URL(string: "\(url)/logout") else {
      completion(GoTrueError(message: "badURL"))
      return
    }

    fetch(
      url: url, method: .post, parameters: [:], headers: ["Authorization": "Bearer \(accessToken)"],
      jsonSerialization: false
    ) { result in
      switch result {
      case .success:
        completion(nil)
      case let .failure(error):
        completion(error)
      }
    }
  }

  func updateUser(
    accessToken: String, emailChangeToken: String?, password: String?, data: [String: Any]? = nil,
    completion: @escaping (Result<User, Error>) -> Void
  ) {
    guard let url = URL(string: "\(url)/user") else {
      completion(.failure(GoTrueError(message: "badURL")))
      return
    }
    var parameters: [String: Any] = [:]
    if let emailChangeToken = emailChangeToken {
      parameters["email_change_token"] = emailChangeToken
    }

    if let password = password {
      parameters["password"] = password
    }

    if let data = data {
      parameters["data"] = data
    }

    fetch(
      url: url, method: .put, parameters: parameters,
      headers: ["Authorization": "Bearer \(accessToken)"]
    ) { result in
      let user = result.flatMap { data in
        Result { try decoder.decode(User.self, from: data) }
      }
      completion(user)
    }
  }

  func getUser(accessToken: String, completion: @escaping (Result<User, Error>) -> Void) {
    guard let url = URL(string: "\(url)/user") else {
      completion(.failure(GoTrueError(message: "badURL")))
      return
    }

    fetch(
      url: url, method: .get, parameters: nil, headers: ["Authorization": "Bearer \(accessToken)"]
    ) { result in
      let user = result.flatMap { data in
        Result { try decoder.decode(User.self, from: data) }
      }
      completion(user)
    }
  }

  private func fetch(
    url: URL, method: HTTPMethod = .get, parameters: [String: Any]?,
    headers: [String: String]? = nil, jsonSerialization: Bool = true,
    completion: @escaping (Result<Data, Error>) -> Void
  ) {
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue

    if var headers = headers {
      headers.merge(self.headers) { $1 }
      request.allHTTPHeaderFields = headers
    } else {
      request.allHTTPHeaderFields = self.headers
    }

    if let parameters = parameters {
      do {
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
      } catch {
        completion(.failure(error))
        return
      }
    }

    let session = URLSession.shared
    let dataTask = session.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let response = response as? HTTPURLResponse else {
        completion(.failure(GoTrueError(message: "failed to get response")))
        return
      }

      guard let data = data else {
        completion(.failure(GoTrueError(message: "empty data")))
        return
      }

      do {
        try Self.validate(data: data, response: response)
        completion(.success(data))
      } catch {
        completion(.failure(error))
      }
    }

    dataTask.resume()
  }

  private static func validate(data: Data, response: HTTPURLResponse) throws {
    if 200..<300 ~= response.statusCode {
      return
    }

    throw try decoder.decode(GoTrueError.self, from: data)
  }
}

private let decoder = { () -> JSONDecoder in
  let dateFormatter = ISO8601DateFormatter()
  dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .custom({ decoder in
    let string = try decoder.singleValueContainer().decode(String.self)
    return dateFormatter.date(from: string)!
  })
  return decoder
}()
