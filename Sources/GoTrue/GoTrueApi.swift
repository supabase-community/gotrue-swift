import AnyCodable
import Foundation
import SimpleHTTP

struct GoTrueHeaders: RequestAdapter {
  var additionalHeaders: [String: String] = [:]

  func adapt(_ client: HTTPClientProtocol, _ request: inout URLRequest) async throws {
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    additionalHeaders.forEach { field, value in
      request.setValue(value, forHTTPHeaderField: field)
    }
  }
}

struct APIKeyRequestAdapter: RequestAdapter {
  let apiKey: String

  func adapt(_ client: HTTPClientProtocol, _ request: inout URLRequest) async throws {
    request.setValue(apiKey, forHTTPHeaderField: "apikey")
  }
}

struct Authenticator: RequestAdapter {
  func adapt(_ client: HTTPClientProtocol, _ request: inout URLRequest) async throws {
    let session = try await Env.sessionManager.session()
    request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
  }
}

struct APIErrorInterceptor: ResponseInterceptor {
  func intercept(_ client: HTTPClientProtocol, _ result: Result<Response, Error>) async throws
    -> Response
  {
    do {
      return try result.get()
    } catch let error as APIError {
      let response = try error.response.decoded(to: ErrorResponse.self)
      throw GoTrueError(
        statusCode: error.response.statusCode,
        message: response.msg ?? response.message
          ?? "Error: status_code=\(error.response.statusCode)"
      )
    } catch {
      throw error
    }
  }

  private struct ErrorResponse: Decodable {
    let msg: String?
    let message: String?
  }
}

extension HTTPClient {
  static func goTrueClient(url: URL, apiKey: String, additionalHeaders: [String: String] = [:])
    -> HTTPClient
  {
    HTTPClient(
      baseURL: url,
      adapters: [
        DefaultHeaders(),
        GoTrueHeaders(additionalHeaders: additionalHeaders),
        APIKeyRequestAdapter(apiKey: apiKey),
      ],
      interceptors: [StatusCodeValidator()]
    )
  }
}

class GoTrueApi {
  func signUpWithEmail(email: String, password: String, options: SignUpOptions) async throws
    -> Session
  {
    struct Body: Encodable {
      let email: String
      let password: String
      let data: AnyEncodable?
    }

    return try await Env.httpClient.request(
      Endpoint(
        path: "signup",
        method: .post,
        query: options.redirectTo.map {
          [URLQueryItem(name: "redirect_to", value: $0.absoluteString)]
        },
        body: try JSONEncoder().encode(Body(email: email, password: password, data: options.data)))
    ).decoded(to: Session.self)
  }

  func signInWithEmail(email: String, password: String, redirectTo: URL?) async throws -> Session {
    try await Env.httpClient.request(
      Endpoint(
        path: "/token",
        method: .post,
        query: [
          URLQueryItem(name: "grant_type", value: "password"),
          redirectTo.map { URLQueryItem(name: "redirect_to", value: $0.absoluteString) },
        ].compactMap { $0 },
        body: try JSONEncoder().encode(["email": email, "password": password])
      )
    ).decoded(to: Session.self)
  }

  func signUpWithPhone(phone: String, password: String, data: AnyEncodable?) async throws -> Session
  {
    struct Body: Encodable {
      let phone: String
      let password: String
      let data: AnyEncodable?
    }

    return try await Env.httpClient.request(
      Endpoint(
        path: "signup",
        method: .post,
        body: try JSONEncoder().encode(Body(phone: phone, password: password, data: data))
      )
    ).decoded(to: Session.self)
  }

  func signInWithPhone(phone: String, password: String) async throws -> Session {
    try await Env.httpClient.request(
      Endpoint(
        path: "token",
        method: .post,
        query: [URLQueryItem(name: "grant_type", value: "password")],
        body: try JSONEncoder().encode(["phone": phone, "password": password])
      )
    ).decoded(to: Session.self)
  }

  func sendMagicLinkEmail(email: String, redirectTo: URL?) async throws {
    _ = try await Env.httpClient.request(
      Endpoint(
        path: "magiclink",
        method: .post,
        query: redirectTo.map { [URLQueryItem(name: "redirect_to", value: $0.absoluteString)] },
        body: try JSONEncoder().encode(["email": email]))
    )
  }

  func sendMobileOTP(phone: String) async throws {
    _ = try await Env.httpClient.request(
      Endpoint(path: "otp", method: .post, body: try JSONEncoder().encode(["phone": phone]))
    )
  }

  func verifyMobileOTP(phone: String, token: String, redirectTo: URL?) async throws -> Session {
    struct Body: Encodable {
      let phone: String
      let token: String
      let type = "sms"
      let redirectTo: URL?
    }

    return try await Env.httpClient.request(
      Endpoint(
        path: "verify",
        method: .post,
        body: try JSONEncoder().encode(Body(phone: phone, token: token, redirectTo: redirectTo))
      )
    ).decoded(to: Session.self)
  }

  func inviteUserByEmail(email: String, options: SignUpOptions) async throws -> User {
    struct Body: Encodable {
      let email: String
      let data: AnyEncodable?
    }

    return try await Env.httpClient.request(
      Endpoint(
        path: "invite",
        method: .post,
        query: options.redirectTo.map {
          [URLQueryItem(name: "redirect_to", value: $0.absoluteString)]
        },
        body: try JSONEncoder().encode(Body(email: email, data: options.data))
      )
    ).decoded(to: User.self)
  }

  func resetPasswordForEmail(email: String, redirectTo: URL?) async throws {

  }

  func getUrlForProvider(provider: Provider, options: ProviderOptions?) throws -> URL {
    guard
      var components = URLComponents(
        url: Env.url().appendingPathComponent("authorize"), resolvingAgainstBaseURL: false)
    else {
      throw GoTrueError.badURL
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
      throw GoTrueError.badURL
    }

    return url
  }

  func refreshAccessToken(refreshToken: String) async throws -> Session {
    try await Env.httpClient.request(
      Endpoint(
        path: "/token", method: .post,
        query: [URLQueryItem(name: "grant_type", value: "refresh_token")],
        body: try JSONEncoder().encode(["refresh_token": refreshToken])
      )
    )
    .decoded(to: Session.self)
  }

  func signOut() async throws {
    _ = try await Env.httpClient.request(
      Endpoint(path: "/logout", method: .post, additionalAdapters: [Authenticator()]))
  }

  func updateUser(params: UpdateUserParams) async throws -> User {
    try await Env.httpClient.request(
      Endpoint(
        path: "/user", method: .put, body: try JSONEncoder().encode(params),
        additionalAdapters: [Authenticator()])
    ).decoded(to: User.self)
  }

  func getUser() async throws -> User {
    try await Env.httpClient.request(
      Endpoint(path: "/user", method: .get, additionalAdapters: [Authenticator()])
    ).decoded(to: User.self)
  }
}
