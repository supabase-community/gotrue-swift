import AnyCodable
import Foundation
import SimpleHTTP

public typealias AuthStateChangeCallback = (_ event: AuthChangeEvent, _ session: Session?) -> Void

public struct Subscription {
  let callback: AuthStateChangeCallback

  public let unsubscribe: () -> Void
}

public class GoTrueClient {
  private var stateChangeListeners: [String: Subscription] = [:]

  /// Receive a notification every time an auth event happens.
  /// - Returns: A subscription object which can be used to unsubscribe itself.
  public func onAuthStateChange(
    _ callback: @escaping (_ event: AuthChangeEvent, _ session: Session?) -> Void
  ) -> Subscription {
    let id = UUID().uuidString

    let subscription = Subscription(
      callback: callback,
      unsubscribe: { [weak self] in
        self?.stateChangeListeners[id] = nil
      }
    )

    stateChangeListeners[id] = subscription
    return subscription
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
    return try await GoTrueApi.signUpWithPhone(phone: phone, password: password, data: options.data)
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
    return try await GoTrueApi.signUpWithEmail(email: email, password: password, options: options)
  }

  /// Log in an existing user with magic link.
  public func signIn(email: String, redirectTo: URL? = nil) async throws {
    await Env.sessionManager.removeSession()
    try await GoTrueApi.sendMagicLinkEmail(email: email, redirectTo: redirectTo)
  }

  /// Log in an existing user with an email and password.
  public func signIn(email: String, password: String, redirectTo: URL? = nil) async throws
    -> Session
  {
    await Env.sessionManager.removeSession()

    let session = try await GoTrueApi.signInWithEmail(
      email: email, password: password, redirectTo: redirectTo)
    if session.user.confirmedAt != nil || session.user.emailConfirmedAt != nil {
      await Env.sessionManager.updateSession(session)
      await notifyAllStateChangeListeners(.signedIn)
    }
    return session
  }

  /// Log in an existing user with an OTP.
  public func signIn(phone: String) async throws {
    await Env.sessionManager.removeSession()
    try await GoTrueApi.sendMobileOTP(phone: phone)
  }

  /// Log in an existing user with phone and password.
  public func signIn(phone: String, password: String) async throws -> Session {
    await Env.sessionManager.removeSession()
    let session = try await GoTrueApi.signInWithPhone(phone: phone, password: password)
    if session.user.phoneConfirmedAt != nil {
      await Env.sessionManager.updateSession(session)
      await notifyAllStateChangeListeners(.signedIn)
    }
    return session
  }

  // Log in via a third-party provider.
  public func signIn(provider: Provider, options: ProviderOptions? = nil) async throws -> URL {
    await Env.sessionManager.removeSession()
    let providerURL = try GoTrueApi.getUrlForProvider(provider: provider, options: options)
    return providerURL
  }

  /// Log in user given a User supplied OTP received via mobile.
  public func verifyOTP(phone: String, token: String, redirectTo: URL? = nil) async throws
    -> Session
  {
    await Env.sessionManager.removeSession()

    let session = try await GoTrueApi.verifyMobileOTP(
      phone: phone, token: token, redirectTo: redirectTo)

    await Env.sessionManager.updateSession(session)
    await notifyAllStateChangeListeners(.signedIn)

    return session
  }

  public func update(user: UpdateUserParams) async throws -> User {
    let user = try await GoTrueApi.updateUser(params: user)

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

    let user = try await GoTrueApi.getUser()
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
    try await GoTrueApi.signOut()
    await notifyAllStateChangeListeners(.signedOut)
    await Env.sessionManager.removeSession()
  }

  private func notifyAllStateChangeListeners(_ event: AuthChangeEvent) async {
    let session = await self.session

    stateChangeListeners.values.forEach {
      $0.callback(event, session)
    }
  }
}

extension GoTrueClient {
  public static func httpClient(url: URL, apiKey: String, additionalHeaders: [String: String] = [:])
    -> HTTPClientProtocol
  {
    HTTPClient.goTrueClient(url: url, apiKey: apiKey, additionalHeaders: additionalHeaders)
  }
}
