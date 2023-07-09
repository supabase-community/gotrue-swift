import Foundation
import Get
import KeychainAccess

typealias SessionRefresher = @Sendable (_ refreshToken: String) async throws -> Session

struct Environment {
  var client: APIClient
  var sessionRefresher: SessionRefresher
  var localStorage: GoTrueLocalStorage
  var sessionManager: SessionManager
  var date: () -> Date
}

extension Environment {
  static func live(
    url: URL,
    localStorage: GoTrueLocalStorage,
    headers: [String: String],
    configuration: (inout APIClient.Configuration) -> Void
  ) -> Environment {
    let client = APIClient(baseURL: url) {
      $0.sessionConfiguration.httpAdditionalHeaders = headers.merging([
        "Content-Type": "application/json",
      ]) { old, _ in old }
      $0.decoder = .goTrue
      $0.encoder = .goTrue
      $0.delegate = Delegate()

      configuration(&$0)
    }

    let sessionRefresher: SessionRefresher = { refreshToken in
      try await client.send(
        Paths.token.post(
          grantType: .refreshToken,
          .userCredentials(UserCredentials(refreshToken: refreshToken))
        )
      ).value
    }
    let sessionManager = SessionManager(
      localStorage: localStorage,
      sessionRefresher: sessionRefresher
    )

    return Environment(
      client: client,
      sessionRefresher: sessionRefresher,
      localStorage: localStorage,
      sessionManager: sessionManager,
      date: Date.init
    )
  }
}

private let dateFormatterWithFractionalSeconds = { () -> ISO8601DateFormatter in
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  return formatter
}()

private let dateFormatter = { () -> ISO8601DateFormatter in
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime]
  return formatter
}()

extension JSONDecoder {
  static let goTrue = { () -> JSONDecoder in
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let string = try container.decode(String.self)

      let supportedFormatters = [dateFormatterWithFractionalSeconds, dateFormatter]

      for formatter in supportedFormatters {
        if let date = formatter.date(from: string) {
          return date
        }
      }

      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "Invalid date format: \(string)"
      )
    }
    return decoder
  }()
}

extension JSONEncoder {
  static let goTrue = { () -> JSONEncoder in
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
    _: APIClient, validateResponse response: HTTPURLResponse, data: Data,
    task _: URLSessionTask
  ) throws {
    if 200 ..< 300 ~= response.statusCode {
      return
    }

    guard let error = try? JSONDecoder.goTrue.decode(GoTrueError.APIError.self, from: data) else {
      throw APIError.unacceptableStatusCode(response.statusCode)
    }

    throw GoTrueError.api(error)
  }
}
