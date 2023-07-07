import Foundation
import Get

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public final class GoTrueClient {
  let env: Environment

  private let url: URL

  private let authEventChangeContinuation: AsyncStream<AuthChangeEvent>.Continuation
  /// Asynchronous sequence of authentication change events emitted during life of `GoTrueClient`.
  public let authEventChange: AsyncStream<AuthChangeEvent>

  private let initializationTask: Task<Void, Never>

  /// Returns the session, refreshing it if necessary.
  public var session: Session {
    get async throws {
      await initialize()
      return try await env.sessionManager.session()
    }
  }

  init(
    url: URL,
    headers: [String: String] = [:],
    localStorage: GoTrueLocalStorage?,
    configuration: (inout APIClient.Configuration) -> Void
  ) {
    var headers = headers
    headers["X-Client-Info"] = "gotrue-swift/\(version)"

    self.url = url

    let env = Environment.live(
      url: url,
      localStorage: localStorage ?? KeychainLocalStorage(
        service: "supabase.gotrue.swift",
        accessGroup: nil
      ),
      headers: headers,
      configuration: configuration
    )
    self.env = env

    let (stream, continuation) = AsyncStream<AuthChangeEvent>.streamWithContinuation()
    authEventChange = stream
    authEventChangeContinuation = continuation
    initializationTask = Task {
      do {
        _ = try await env.sessionManager.session()
        continuation.yield(.signedIn)
      } catch {
        continuation.yield(.signedOut)
      }
    }
  }

  public convenience init(
    url: URL,
    headers: [String: String] = [:],
    localStorage: GoTrueLocalStorage? = nil
  ) {
    self.init(
      url: url,
      headers: headers,
      localStorage: localStorage,
      configuration: { _ in }
    )
  }

  /// Initialize the client session from storage.
  ///
  /// This method is called automatically when instantiating the client, but it's recommended to
  /// call this method on the app startup, for making sure that the client is fully initialized
  /// before proceeding.
  public func initialize() async {
    await initializationTask.value
  }

  /// Creates a new user.
  /// - Parameters:
  ///   - email: User's email address.
  ///   - password: Password for the user.
  ///   - data: User's metadata.
  @discardableResult
  public func signUp(
    email: String,
    password: String,
    data: [String: AnyJSON]? = nil,
    redirectTo: URL? = nil,
    captchaToken: String? = nil
  ) async throws -> AuthResponse {
    try await _signUp(
      request: Paths.signup.post(
        redirectTo: redirectTo,
        .init(
          email: email,
          password: password,
          data: data,
          gotrueMetaSecurity: captchaToken.map(GoTrueMetaSecurity.init(captchaToken:))
        )
      )
    )
  }

  /// Creates a new user.
  /// - Parameters:
  ///   - phone: User's phone number with international prefix.
  ///   - password: Password for the user.
  ///   - data: User's metadata.
  @discardableResult
  public func signUp(
    phone: String,
    password: String,
    data: [String: AnyJSON]? = nil,
    captchaToken: String? = nil
  ) async throws -> AuthResponse {
    try await _signUp(
      request: Paths.signup.post(
        .init(
          password: password,
          phone: phone,
          data: data,
          gotrueMetaSecurity: captchaToken.map(GoTrueMetaSecurity.init(captchaToken:))
        )
      )
    )
  }

  private func _signUp(request: Request<AuthResponse>) async throws -> AuthResponse {
    await env.sessionManager.remove()
    let response = try await env.client.send(request).value

    if let session = response.session {
      try await env.sessionManager.update(session)
      authEventChangeContinuation.yield(.signedIn)
    }

    return response
  }

  /// Log in an existing user with an email and password.
  @discardableResult
  public func signIn(email: String, password: String) async throws -> Session {
    try await _signIn(
      request: Paths.token.post(
        grantType: .password,
        .userCredentials(UserCredentials(email: email, password: password))
      )
    )
  }

  /// Log in an existing user with a phone and password.
  @discardableResult
  public func signIn(phone: String, password: String) async throws -> Session {
    try await _signIn(
      request: Paths.token.post(
        grantType: .password,
        .userCredentials(UserCredentials(password: password, phone: phone))
      )
    )
  }

  /// Allows signing in with an ID token issued by certain supported providers.
  /// The ID token is verified for validity and a new session is established.
  @_spi(Experimental)
  @discardableResult
  public func signInWithIdToken(credentials: OpenIDConnectCredentials) async throws -> Session {
    try await _signIn(
      request: Paths.token.post(
        grantType: .idToken,
        .openIDConnectCredentials(credentials)
      )
    )
  }

  private func _signIn(request: Request<Session>) async throws -> Session {
    await env.sessionManager.remove()

    let session = try await env.client.send(request).value

    if session.user.emailConfirmedAt != nil || session.user.confirmedAt != nil {
      try await env.sessionManager.update(session)
      authEventChangeContinuation.yield(.signedIn)
    }

    return session
  }

  /// Log in user using magic link.
  ///
  /// If the `{{ .ConfirmationURL }}` variable is specified in the email template, a magic link will
  /// be sent.
  /// If the `{{ .Token }}` variable is specified in the email template, an OTP will be sent.
  /// - Parameters:
  ///   - email: User's email address.
  ///   - redirectTo: Redirect URL embedded in the email link.
  ///   - shouldCreateUser: Creates a new user, defaults to `true`.
  ///   - data: User's metadata.
  ///   - captchaToken: Captcha verification token.
  public func signInWithOTP(
    email: String,
    redirectTo: URL? = nil,
    shouldCreateUser: Bool? = nil,
    data: [String: AnyJSON]? = nil,
    captchaToken: String? = nil
  ) async throws {
    await env.sessionManager.remove()
    try await env.client.send(
      Paths.otp.post(
        redirectTo: redirectTo,
        .init(
          email: email,
          createUser: shouldCreateUser,
          data: data,
          gotrueMetaSecurity: captchaToken.map(GoTrueMetaSecurity.init(captchaToken:))
        )
      )
    )
  }

  /// Log in user using a one-time password (OTP)..
  ///
  /// - Parameters:
  ///   - phone: User's phone with international prefix.
  ///   - shouldCreateUser: Creates a new user, defaults to `true`.
  ///   - data: User's metadata.
  ///   - captchaToken: Captcha verification token.
  public func signInWithOTP(
    phone: String,
    shouldCreateUser: Bool? = nil,
    data: [String: AnyJSON]? = nil,
    captchaToken: String? = nil
  ) async throws {
    await env.sessionManager.remove()
    try await env.client.send(
      Paths.otp.post(
        .init(
          phone: phone,
          createUser: shouldCreateUser,
          data: data,
          gotrueMetaSecurity: captchaToken.map(GoTrueMetaSecurity.init(captchaToken:))
        )
      )
    )
  }

  /// Log in an existing user via a third-party provider.
  public func getOAuthSignInURL(
    provider: Provider,
    scopes: String? = nil,
    redirectTo: URL? = nil,
    queryParams: [(name: String, value: String?)] = []
  ) throws -> URL {
    guard
      var components = URLComponents(
        url: url.appendingPathComponent("authorize"), resolvingAgainstBaseURL: false
      )
    else {
      throw URLError(.badURL)
    }

    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "provider", value: provider.rawValue),
    ]

    if let scopes {
      queryItems.append(URLQueryItem(name: "scopes", value: scopes))
    }

    if let redirectTo {
      queryItems.append(URLQueryItem(name: "redirect_to", value: redirectTo.absoluteString))
    }

    queryItems.append(contentsOf: queryParams.map(URLQueryItem.init))

    components.queryItems = queryItems

    guard let url = components.url else {
      throw URLError(.badURL)
    }

    return url
  }

  @discardableResult
  public func refreshSession(refreshToken: String) async throws -> Session {
    do {
      let session = try await env.client.send(
        Paths.token.post(
          grantType: .refreshToken,
          .userCredentials(UserCredentials(refreshToken: refreshToken))
        )
      ).value

      if session.user.phoneConfirmedAt != nil || session.user.emailConfirmedAt != nil || session
        .user.confirmedAt != nil
      {
        try await env.sessionManager.update(session)
        authEventChangeContinuation.yield(.signedIn)
      }

      return session
    } catch {
      throw error
    }
  }

  /// Gets the session data from a OAuth2 callback URL.
  @discardableResult
  public func session(from url: URL, storeSession: Bool = true) async throws -> Session {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      throw URLError(.badURL)
    }

    let params = extractParams(from: components.fragment ?? "")

    if let errorDescription = params.first(where: { $0.name == "error_description" })?.value {
      throw GoTrueError.api(.init(errorDescription: errorDescription))
    }

    guard
      let accessToken = params.first(where: { $0.name == "access_token" })?.value,
      let expiresIn = params.first(where: { $0.name == "expires_in" })?.value,
      let refreshToken = params.first(where: { $0.name == "refresh_token" })?.value,
      let tokenType = params.first(where: { $0.name == "token_type" })?.value
    else {
      throw URLError(.badURL)
    }

    let providerToken = params.first(where: { $0.name == "provider_token" })?.value
    let providerRefreshToken = params.first(where: { $0.name == "provider_refresh_token" })?.value

    let user = try await env.client.send(
      Paths.user.get.withAuthorization(accessToken, type: tokenType)
    ).value

    let session = Session(
      providerToken: providerToken,
      providerRefreshToken: providerRefreshToken,
      accessToken: accessToken,
      tokenType: tokenType,
      expiresIn: Double(expiresIn) ?? 0,
      refreshToken: refreshToken,
      user: user
    )

    if storeSession {
      try await env.sessionManager.update(session)
      authEventChangeContinuation.yield(.signedIn)

      if let type = params.first(where: { $0.name == "type" })?.value, type == "recovery" {
        authEventChangeContinuation.yield(.passwordRecovery)
      }
    }

    return session
  }

  /// Sets the session data from the current session. If the current session is expired, setSession
  /// will take care of refreshing it to obtain a new session.
  ///
  /// If the refresh token is invalid and the current session has expired, an error will be thrown.
  /// This method will use the exp claim defined in the access token.
  /// - Parameters:
  ///   - accessToken: The current access token.
  ///   - refreshToken: The current refresh token.
  /// - Returns: A new valid session.
  @discardableResult
  public func setSession(accessToken: String, refreshToken: String) async throws -> Session {
    let now = Date()
    var expiresAt = now
    var hasExpired = true
    var session: Session?

    let jwt = try decode(jwt: accessToken)
    if let exp = jwt["exp"] as? TimeInterval {
      expiresAt = Date(timeIntervalSince1970: exp)
      hasExpired = expiresAt <= now
    } else {
      throw GoTrueError.missingExpClaim
    }

    if hasExpired {
      session = try await refreshSession(refreshToken: refreshToken)
    } else {
      let user = try await env.client.send(
        Paths.user.get.withAuthorization(accessToken)
      ).value
      session = Session(
        accessToken: accessToken,
        tokenType: "bearer",
        expiresIn: expiresAt.timeIntervalSince(now),
        refreshToken: refreshToken,
        user: user
      )
    }

    guard let session else {
      throw GoTrueError.sessionNotFound
    }

    try await env.sessionManager.update(session)
    authEventChangeContinuation.yield(.tokenRefreshed)
    return session
  }

  /// Signs out the current user, if there is a logged in user.
  public func signOut() async throws {
    defer { authEventChangeContinuation.yield(.signedOut) }

    let session = try? await env.sessionManager.session()
    await env.sessionManager.remove()

    if let session {
      try await env.client.send(Paths.logout.post.withAuthorization(session.accessToken)).value
    }
  }

  /// Log in an user given a User supplied OTP received via email.
  @discardableResult
  public func verifyOTP(
    email: String,
    token: String,
    type: OTPType,
    redirectTo: URL? = nil,
    captchaToken: String? = nil
  ) async throws -> AuthResponse {
    try await _verifyOTP(
      request: Paths.verify.post(
        redirectTo: redirectTo,
        .init(
          email: email,
          token: token,
          type: type,
          gotrueMetaSecurity: captchaToken.map(GoTrueMetaSecurity.init(captchaToken:))
        )
      )
    )
  }

  /// Log in an user given a User supplied OTP received via mobile.
  @discardableResult
  public func verifyOTP(
    phone: String,
    token: String,
    type: OTPType,
    captchaToken: String? = nil
  ) async throws -> AuthResponse {
    try await _verifyOTP(
      request: Paths.verify.post(
        .init(
          phone: phone,
          token: token,
          type: type,
          gotrueMetaSecurity: captchaToken.map(GoTrueMetaSecurity.init(captchaToken:))
        )
      )
    )
  }

  private func _verifyOTP(request: Request<AuthResponse>) async throws -> AuthResponse {
    await env.sessionManager.remove()

    let response = try await env.client.send(request).value

    if let session = response.session {
      try await env.sessionManager.update(session)
      authEventChangeContinuation.yield(.signedIn)
    }

    return response
  }

  /// Updates user data, if there is a logged in user.
  @discardableResult
  public func update(user: UserAttributes) async throws -> User {
    var session = try await env.sessionManager.session()
    let user = try await env.client.send(
      Paths.user.put(user).withAuthorization(session.accessToken)
    ).value
    session.user = user
    try await env.sessionManager.update(session)
    authEventChangeContinuation.yield(.userUpdated)
    return user
  }

  /// Sends a reset request to an email address.
  public func resetPasswordForEmail(
    _ email: String,
    redirectTo: URL? = nil,
    captchaToken: String? = nil
  ) async throws {
    try await env.client.send(
      Paths.recover.post(
        redirectTo: redirectTo,
        RecoverParams(
          email: email,
          gotrueMetaSecurity: captchaToken.map(GoTrueMetaSecurity.init(captchaToken:))
        )
      )
    ).value
  }
}
