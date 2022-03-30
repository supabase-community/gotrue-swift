import ComposableKeychain
import Foundation
import Get
import GoTrueHTTP
import KeychainAccess

typealias SessionRefresher = (_ refreshToken: String) async throws -> Session

struct Environment {
  var client: APIClient
  var sessionRefresher: SessionRefresher
  var keychain: KeychainClient
  var sessionManager: SessionManager
  var date: () -> Date
}

var Current: Environment!

extension Environment {
  static func live(
    url: URL,
    accessGroup: String?,
    headers: [String: String]
  ) -> Environment {
    guard let host = URLComponents(url: url, resolvingAgainstBaseURL: false)?.host else {
      preconditionFailure("Invalid URL provided: \(url)")
    }

    let client = APIClient(host: host) {
      $0.sessionConfiguration.httpAdditionalHeaders = headers.merging([
        "Content-Type": "application/json"
      ]) { old, _ in old }
    }

    return Environment(
      client: client,
      sessionRefresher: { refreshToken in
        try await Current.client.send(
          Paths.token.post(
            grantType: .refreshToken,
            .userCredentials(UserCredentials(refreshToken: refreshToken)))
        ).value
      },
      keychain: .live(
        keychain: accessGroup.map { Keychain(service: "supabase.gotrue.swift", accessGroup: $0) }
          ?? Keychain(service: "supabase.gotrue.swift")
      ),
      sessionManager: .live,
      date: Date.init
    )
  }
}
