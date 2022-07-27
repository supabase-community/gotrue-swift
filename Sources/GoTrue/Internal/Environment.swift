import ComposableKeychain
import Foundation
import Get
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
    headers: [String: String],
    configuration: (inout APIClient.Configuration) -> Void
  ) -> Environment {
    let client = APIClient(baseURL: url) {
      $0.sessionConfiguration.httpAdditionalHeaders = headers.merging([
        "Content-Type": "application/json"
      ]) { old, _ in old }
      $0.decoder = .goTrue
      $0.encoder = .goTrue
      $0.delegate = Delegate()

      configuration(&$0)
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

private let dateFormatter = { () -> ISO8601DateFormatter in
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  return formatter
}()

extension JSONDecoder {
  public static let goTrue = { () -> JSONDecoder in
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let string = try container.decode(String.self)

      guard let date = dateFormatter.date(from: string) else {
        throw DecodingError.dataCorruptedError(
          in: container, debugDescription: "Invalid date format: \(string)")
      }

      return date
    }
    return decoder
  }()
}

extension JSONEncoder {
  public static let goTrue = { () -> JSONEncoder in
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .custom { date, encoder in
      var container = encoder.singleValueContainer()
      let string = dateFormatter.string(from: date)
      try container.encode(string)
    }
    return encoder
  }()
}

private struct Delegate: APIClientDelegate {
  func client(
    _ client: APIClient, validateResponse response: HTTPURLResponse, data: Data,
    task: URLSessionTask
  ) throws {
    if 200..<300 ~= response.statusCode {
      return
    }

    guard let error = try? JSONDecoder.goTrue.decode(GoTrueError.self, from: data) else {
      throw APIError.unacceptableStatusCode(response.statusCode)
    }

    throw error
  }
}
