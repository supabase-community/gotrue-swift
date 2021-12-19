import AnyCodable
import Combine
import Foundation
import SimpleHTTP

public class GoTrueClient {
  private let authStateChangeSubject = PassthroughSubject<AuthChangeEvent, Never>()
  public var authStateChangePublisher: AnyPublisher<AuthChangeEvent, Never> {
    authStateChangeSubject.eraseToAnyPublisher()
  }

  /// Returns the session data, if there is an active session.
  public var session: Session? {
    get async { try? await Env.sessionManager.session() }
  }

  public init(
    url: URL,
    apiKey: String,
    additionalHeaders: [String: String] = [:],
    keychainAccessGroup: String? = nil
  ) {
    Env = Environment(
      url: { url },
      httpClient: GoTrueClient.httpClient(
        url: url, apiKey: apiKey, additionalHeaders: additionalHeaders),
      api: .live,
      sessionStorage: .keychain(accessGroup: keychainAccessGroup),
      sessionManager: .live
    )

    Task {
      guard await session != nil else { return }
      await notifyAllStateChangeListeners(.signedIn)
    }
  }

  /// Creates a new user.
  /// - Parameters:
  ///   - phone: The user's phone number.
  ///   - password: The user's password.
  ///   - options: Additional optionals for creating a new user.
  /// - Returns: A new user.
  public func signUp(phone: String, password: String, options: SignUpOptions = SignUpOptions())
    async throws -> Session
  {
    await Env.sessionManager.removeSession()
    return try await Env.api.signUpWithPhone(phone, password, options.data)
  }

  /// Creates a new user.
  /// - Parameters:
  ///   - email: The user's email address.
  ///   - password: The user's password.
  ///   - options: Additional optionals for creating a new user.
  /// - Returns: A new user.
  public func signUp(email: String, password: String, options: SignUpOptions = SignUpOptions())
    async throws -> Session
  {
    await Env.sessionManager.removeSession()
    return try await Env.api.signUpWithEmail(email, password, options)
  }

  /// Log in an existing user with magic link.
  public func signIn(email: String, redirectTo: URL? = nil) async throws {
    await Env.sessionManager.removeSession()
    try await Env.api.sendMagicLinkEmail(email, redirectTo)
  }

  /// Log in an existing user with an email and password.
  public func signIn(email: String, password: String, redirectTo: URL? = nil) async throws
    -> Session
  {
    await Env.sessionManager.removeSession()

    let session = try await Env.api.signInWithEmail(email, password, redirectTo)
    if session.user.confirmedAt != nil || session.user.emailConfirmedAt != nil {
      await Env.sessionManager.updateSession(session)
      await notifyAllStateChangeListeners(.signedIn)
    }
    return session
  }

  /// Log in an existing user with an OTP.
  public func signIn(phone: String) async throws {
    await Env.sessionManager.removeSession()
    try await Env.api.sendMobileOTP(phone)
  }

  /// Log in an existing user with phone and password.
  public func signIn(phone: String, password: String) async throws -> Session {
    await Env.sessionManager.removeSession()
    let session = try await Env.api.signInWithPhone(phone, password)
    if session.user.phoneConfirmedAt != nil {
      await Env.sessionManager.updateSession(session)
      await notifyAllStateChangeListeners(.signedIn)
    }
    return session
  }

  // Log in via a third-party provider.
  public func signIn(provider: Provider, options: ProviderOptions? = nil) async throws -> URL {
    await Env.sessionManager.removeSession()
    let providerURL = try Env.api.getUrlForProvider(provider, options)
    return providerURL
  }

  /// Log in user given a User supplied OTP received via mobile.
  public func verifyOTP(phone: String, token: String, redirectTo: URL? = nil) async throws
    -> Session
  {
    await Env.sessionManager.removeSession()

    let session = try await Env.api.verifyMobileOTP(phone, token, redirectTo)

    await Env.sessionManager.updateSession(session)
    await notifyAllStateChangeListeners(.signedIn)

    return session
  }

  public func update(user: UpdateUserParams) async throws -> User {
    let user = try await Env.api.updateUser(user)

    await Env.sessionManager.updateUser(user)
    await notifyAllStateChangeListeners(.userUpdated)

    return user
  }

  public func getSessionFromUrl(url: String) async throws -> Session {
    let components = URLComponents(string: url)

    guard
      let queryItems = components?.queryItems,
      let accessToken = queryItems["access_token"],
      let expiresIn = queryItems["expires_in"],
      let refreshToken = queryItems["refresh_token"],
      let tokenType = queryItems["token_type"]
    else {
      throw GoTrueError.badCredentials
    }

    let providerToken = queryItems["provider_token"]

    let user = try await Env.api.getUser()
    let session = Session(
      accessToken: accessToken, tokenType: tokenType, expiresIn: Int(expiresIn) ?? 0,
      refreshToken: refreshToken, providerToken: providerToken, user: user
    )
    await Env.sessionManager.updateSession(session)
    await notifyAllStateChangeListeners(.signedIn)

    if let type = queryItems["type"], type == "recovery" {
      await notifyAllStateChangeListeners(.passwordRecovery)
    }

    return session
  }

  public func signOut() async throws {
    try await Env.api.signOut()
    await notifyAllStateChangeListeners(.signedOut)
    await Env.sessionManager.removeSession()
  }

  private func notifyAllStateChangeListeners(_ event: AuthChangeEvent) async {
    authStateChangeSubject.send(event)
  }
}

extension GoTrueClient {
  /// Provides a HTTPClient capable of authenticating requests using `apiKey` and `GoTrue` token.
  public static func httpClient(url: URL, apiKey: String, additionalHeaders: [String: String] = [:])
    -> HTTPClientProtocol
  {
    HTTPClient.goTrueClient(url: url, apiKey: apiKey, additionalHeaders: additionalHeaders)
  }
}
