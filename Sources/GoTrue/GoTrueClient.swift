import Combine
import Foundation
import Get
import GoTrueHTTP

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public final class GoTrueClient {
  private let client: APIClient
  private let authEventChangeSubject: CurrentValueSubject<AuthChangeEvent, Never>
  private let sessionManager: SessionManager

  public lazy var authEventChange = authEventChangeSubject.share().eraseToAnyPublisher()

  public var session: Session? { sessionManager.storedSession }

  public init(
    url: URL,
    headers: [String: String] = [:],
    keychainAccessGroup: String? = nil
  ) {
    guard let host = URLComponents(url: url, resolvingAgainstBaseURL: false)?.host else {
      preconditionFailure("Invalid URL provided: \(url)")
    }

    self.client = APIClient(host: host) {
      $0.sessionConfiguration.httpAdditionalHeaders = headers
    }
    self.sessionManager = SessionManager(accessGroup: keychainAccessGroup) {
      [client] refreshToken in
      try await client.send(
        Paths.token.post(grantType: .refreshToken, TokenRequest(refreshToken: refreshToken))
      ).value
    }

    self.authEventChangeSubject = CurrentValueSubject<AuthChangeEvent, Never>(
      sessionManager.storedSession != nil ? .signedIn : .signedOut
    )
  }

  public func signUp(email: String, password: String) async throws -> Paths.Signup.PostResponse {
    await sessionManager.remove()
    return try await client.send(Paths.signup.post(.init(email: email, password: password))).value
  }

  public func signIn(email: String, password: String) async throws -> Session {
    await sessionManager.remove()

    do {
      let session = try await client.send(
        Paths.token.post(grantType: .password, TokenRequest(email: email, password: password))
      ).value
      try await sessionManager.update(session)
      authEventChangeSubject.send(.signedIn)
      return session
    } catch {
      throw error
    }
  }
}
