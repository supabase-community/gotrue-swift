import Combine
import Foundation
import GoTrueHTTP

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public final class GoTrueClient {
  private let authEventChangeSubject: CurrentValueSubject<AuthChangeEvent, Never>
  public lazy var authEventChange = authEventChangeSubject.share().eraseToAnyPublisher()

  public var session: Session? { Current.sessionManager.storedSession() }

  public init(
    url: URL,
    headers: [String: String] = [:],
    keychainAccessGroup: String? = nil
  ) {
    Current = .live(url: url, accessGroup: keychainAccessGroup, headers: headers)

    self.authEventChangeSubject = CurrentValueSubject<AuthChangeEvent, Never>(
      Current.sessionManager.storedSession() != nil ? .signedIn : .signedOut
    )
  }

  public func signUp(email: String, password: String) async throws -> Paths.Signup.PostResponse {
    await Current.sessionManager.remove()
    return try await Current.client.send(
      Paths.signup.post(.init(email: email, password: password))
    ).value
  }

  public func signIn(email: String, password: String) async throws -> Session {
    await Current.sessionManager.remove()

    do {
      let session = try await Current.client.send(
        Paths.token.post(
          grantType: .password,
          .userCredentials(UserCredentials(email: email, password: password)))
      ).value
      try await Current.sessionManager.update(session)
      authEventChangeSubject.send(.signedIn)
      return session
    } catch {
      throw error
    }
  }

  public func sendMagicLink(
    params: OTPParams?, redirectURL: URL? = nil
  ) async throws {
    try await Current.client.send(Paths.otp.post(redirectURL: redirectURL, params)).value
  }
}
