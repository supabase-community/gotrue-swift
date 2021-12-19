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

struct API {
  var signUpWithEmail:
    (_ email: String, _ password: String, _ options: SignUpOptions) async throws -> Session
  var signInWithEmail:
    (_ email: String, _ password: String, _ redirectTo: URL?) async throws -> Session
  var signUpWithPhone:
    (_ phone: String, _ password: String, _ data: AnyEncodable?) async throws -> Session
  var signInWithPhone: (_ phone: String, _ password: String) async throws -> Session
  var sendMagicLinkEmail: (_ email: String, _ redirectTo: URL?) async throws -> Void
  var sendMobileOTP: (_ phone: String) async throws -> Void
  var verifyMobileOTP:
    (_ phone: String, _ token: String, _ redirectTo: URL?) async throws -> Session
  var inviteUserByEmail: (_ email: String, _ options: SignUpOptions) async throws -> User
  var resetPasswordForEmail: (_ email: String, _ redirectTo: URL?) async throws -> Void
  var getUrlForProvider: (_ provider: Provider, _ options: ProviderOptions?) throws -> URL
  var refreshAccessToken: (_ refreshToken: String) async throws -> Session
  var signOut: () async throws -> Void
  var updateUser: (_ params: UpdateUserParams) async throws -> User
  var getUser: () async throws -> User
}

extension API {
  static var live: API {
    API(
      signUpWithEmail: GoTrueApi.signUpWithEmail(email:password:options:),
      signInWithEmail: GoTrueApi.signInWithEmail(email:password:redirectTo:),
      signUpWithPhone: GoTrueApi.signUpWithPhone(phone:password:data:),
      signInWithPhone: GoTrueApi.signInWithPhone(phone:password:),
      sendMagicLinkEmail: GoTrueApi.sendMagicLinkEmail(email:redirectTo:),
      sendMobileOTP: GoTrueApi.sendMobileOTP(phone:),
      verifyMobileOTP: GoTrueApi.verifyMobileOTP(phone:token:redirectTo:),
      inviteUserByEmail: GoTrueApi.inviteUserByEmail(email:options:),
      resetPasswordForEmail: GoTrueApi.resetPasswordForEmail(email:redirectTo:),
      getUrlForProvider: GoTrueApi.getUrlForProvider(provider:options:),
      refreshAccessToken: GoTrueApi.refreshAccessToken(refreshToken:),
      signOut: GoTrueApi.signOut,
      updateUser: GoTrueApi.updateUser(params:),
      getUser: GoTrueApi.getUser
    )
  }
}

#if DEBUG
  import XCTestDynamicOverlay
  extension API {
    static var failing: API {
      API(
        signUpWithEmail: { _, _, _ in
          XCTFail("API.signUpWithEmail was not implemented.")
          return .dummy
        },
        signInWithEmail: { _, _, _ in
          XCTFail("API.signInWithEmail was not implemented.")
          return .dummy
        },
        signUpWithPhone: { _, _, _ in
          XCTFail("API.signUpWithPhone was not implemented.")
          return .dummy
        },
        signInWithPhone: { _, _ in
          XCTFail("API.signInWithPhone was not implemented.")
          return .dummy
        },
        sendMagicLinkEmail: { _, _ in
          XCTFail("API.sendMagicLinkEmail was not implemented.")
        },
        sendMobileOTP: { _ in
          XCTFail("API.sendMobileOTP was not implemented.")
        },
        verifyMobileOTP: { _, _, _ in
          XCTFail("API.verifyMobileOTP was not implemented.")
          return .dummy
        },
        inviteUserByEmail: { _, _ in
          XCTFail("API.inviteUserByEmail was not implemented.")
          return .dummy
        },
        resetPasswordForEmail: { _, _ in
          XCTFail("API.resetPasswordForEmail was not implemented.")
        },
        getUrlForProvider: { _, _ in
          XCTFail("API.getUrlForProvider was not implemented.")
          return URL(string: "https://test.com")!
        },
        refreshAccessToken: { _ in
          XCTFail("API.refreshAccessToken was not implemented.")
          return .dummy
        },
        signOut: {
          XCTFail("API.signOut was not implemented.")
        },
        updateUser: { _ in
          XCTFail("API.updateUser was not implemented.")
          return .dummy
        },
        getUser: {
          XCTFail("API.getUser was not implemented.")
          return .dummy
        }
      )
    }

    static var noop: API {
      API(
        signUpWithEmail: { _, _, _ in
          return .dummy
        },
        signInWithEmail: { _, _, _ in
          return .dummy
        },
        signUpWithPhone: { _, _, _ in
          return .dummy
        },
        signInWithPhone: { _, _ in
          return .dummy
        },
        sendMagicLinkEmail: { _, _ in
        },
        sendMobileOTP: { _ in
        },
        verifyMobileOTP: { _, _, _ in
          return .dummy
        },
        inviteUserByEmail: { _, _ in
          return .dummy
        },
        resetPasswordForEmail: { _, _ in
        },
        getUrlForProvider: { _, _ in
          return URL(string: "https://test.com")!
        },
        refreshAccessToken: { _ in
          return .dummy
        },
        signOut: {
        },
        updateUser: { _ in
          return .dummy
        },
        getUser: {
          return .dummy
        }
      )
    }
  }
#endif

private enum GoTrueApi {
  static func signUpWithEmail(email: String, password: String, options: SignUpOptions) async throws
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

  static func signInWithEmail(email: String, password: String, redirectTo: URL?) async throws
    -> Session
  {
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

  static func signUpWithPhone(phone: String, password: String, data: AnyEncodable?) async throws
    -> Session
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

  static func signInWithPhone(phone: String, password: String) async throws -> Session {
    try await Env.httpClient.request(
      Endpoint(
        path: "token",
        method: .post,
        query: [URLQueryItem(name: "grant_type", value: "password")],
        body: try JSONEncoder().encode(["phone": phone, "password": password])
      )
    ).decoded(to: Session.self)
  }

  static func sendMagicLinkEmail(email: String, redirectTo: URL?) async throws {
    _ = try await Env.httpClient.request(
      Endpoint(
        path: "magiclink",
        method: .post,
        query: redirectTo.map { [URLQueryItem(name: "redirect_to", value: $0.absoluteString)] },
        body: try JSONEncoder().encode(["email": email]))
    )
  }

  static func sendMobileOTP(phone: String) async throws {
    _ = try await Env.httpClient.request(
      Endpoint(path: "otp", method: .post, body: try JSONEncoder().encode(["phone": phone]))
    )
  }

  static func verifyMobileOTP(phone: String, token: String, redirectTo: URL?) async throws
    -> Session
  {
    var body = [
      "phone": phone,
      "token": token,
      "type": "sms",
    ]
    body["redirect_to"] = redirectTo?.absoluteString

    return try await Env.httpClient.request(
      Endpoint(
        path: "verify",
        method: .post,
        body: try JSONEncoder().encode(body)
      )
    ).decoded(to: Session.self)
  }

  static func inviteUserByEmail(email: String, options: SignUpOptions) async throws -> User {
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

  static func resetPasswordForEmail(email: String, redirectTo: URL?) async throws {
    _ = try await Env.httpClient.request(
      Endpoint(
        path: "recover",
        method: .post,
        query: redirectTo.map {
          [URLQueryItem(name: "redirect_to", value: $0.absoluteString)]
        },
        body: try JSONEncoder().encode(["email": email])
      )
    )
  }

  static func getUrlForProvider(provider: Provider, options: ProviderOptions?) throws -> URL {
    guard
      var components = URLComponents(
        url: Env.url().appendingPathComponent("authorize"), resolvingAgainstBaseURL: false)
    else {
      throw GoTrueError.badURL
    }

    let queryItems = [
      URLQueryItem(name: "provider", value: provider.rawValue),
      options?.scopes.map {
        URLQueryItem(name: "scopes", value: $0)
      },
      options?.redirectTo.map {
        URLQueryItem(name: "redirect_to", value: $0)
      },
    ].compactMap { $0 }

    components.queryItems = queryItems

    guard let url = components.url else {
      throw GoTrueError.badURL
    }

    return url
  }

  static func refreshAccessToken(refreshToken: String) async throws -> Session {
    try await Env.httpClient.request(
      Endpoint(
        path: "/token", method: .post,
        query: [URLQueryItem(name: "grant_type", value: "refresh_token")],
        body: try JSONEncoder().encode(["refresh_token": refreshToken])
      )
    )
    .decoded(to: Session.self)
  }

  static func signOut() async throws {
    _ = try await Env.httpClient.request(
      Endpoint(path: "/logout", method: .post, additionalAdapters: [Authenticator()]))
  }

  static func updateUser(params: UpdateUserParams) async throws -> User {
    try await Env.httpClient.request(
      Endpoint(
        path: "/user", method: .put, body: try JSONEncoder().encode(params),
        additionalAdapters: [Authenticator()])
    ).decoded(to: User.self)
  }

  static func getUser() async throws -> User {
    try await Env.httpClient.request(
      Endpoint(path: "/user", method: .get, additionalAdapters: [Authenticator()])
    ).decoded(to: User.self)
  }
}
