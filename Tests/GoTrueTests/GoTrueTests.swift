import Mocker
import XCTest

@testable @_spi(Experimental) import GoTrue

final class InMemoryLocalStorage: GoTrueLocalStorage, @unchecked Sendable {
  private let queue = DispatchQueue(label: "InMemoryLocalStorage")
  private var storage: [String: Data] = [:]

  func store(key: String, value: Data) throws {
    queue.sync {
      storage[key] = value
    }
  }

  func retrieve(key: String) throws -> Data? {
    queue.sync {
      storage[key]
    }
  }

  func remove(key: String) throws {
    queue.sync {
      storage[key] = nil
    }
  }
}

final class GoTrueTests: XCTestCase {
  static let baseURL = URL(string: "http://localhost:54321/auth/v1")!

  let sut = GoTrueClient(
    url: GoTrueTests.baseURL,
    headers: ["apikey": "dummy.api.key"],
    localStorage: InMemoryLocalStorage()
  ) {
    $0.sessionConfiguration.protocolClasses = [MockingURLProtocol.self]
  }

  func testDecodeUser() {
    XCTAssertNoThrow(
      try JSONDecoder.goTrue.decode(User.self, from: json(named: "user"))
    )
  }

  func testDecodeSessionOrUser() {
    XCTAssertNoThrow(
      try JSONDecoder.goTrue.decode(
        AuthResponse.self, from: json(named: "session")
      )
    )
  }

  #if !os(watchOS)
    func test_signUpWithEmailAndPassword() async throws {
      Mock.post(path: "signup", json: "signup-response").register()

      let user = try await sut.signUp(email: "guilherme@grds.dev", password: "thepass").user

      XCTAssertEqual(user?.email, "guilherme@grds.dev")
    }

    func testSignInWithIdToken() async throws {
      Mock(
        url: URL(string: "http://localhost:54321/auth/v1/token?grant_type=id_token")!,
        dataType: .json,
        statusCode: 200,
        data: [.post: json(named: "session")]
      ).register()

      let session = try await sut
        .signInWithIdToken(credentials: OpenIDConnectCredentials(idToken: "dummy-token-1234"))
      XCTAssertEqual(session.user.email, "guilherme@binaryscraping.co")
    }
  #endif

  func testSignInWithProvider() throws {
    let url = try sut.getOAuthSignInURL(
      provider: .github, scopes: "read,write",
      redirectTo: URL(string: "https://dummy-url.com/redirect")!,
      queryParams: [("extra_key", "extra_value")]
    )
    XCTAssertEqual(
      url,
      URL(
        string:
        "http://localhost:54321/auth/v1/authorize?provider=github&scopes=read,write&redirect_to=https://dummy-url.com/redirect&extra_key=extra_value"
      )!
    )
  }

  func testSessionFromURL() async throws {
    let url = URL(
      string:
      "https://dummy-url.com/callback#access_token=accesstoken&expires_in=60&refresh_token=refreshtoken&token_type=bearer"
    )!

    var mock = Mock.get(path: "user", json: "user")
    mock.onRequestHandler = OnRequestHandler(httpBodyType: Session?.self) { request, _ in
      let authorizationHeader = request.allHTTPHeaderFields?["Authorization"]
      XCTAssertEqual(authorizationHeader, "bearer accesstoken")
    }
    mock.register()

    let session = try await sut.session(from: url)
    let expectedSession = Session(
      accessToken: "accesstoken",
      tokenType: "bearer",
      expiresIn: 60,
      refreshToken: "refreshtoken",
      user: User(fromMockNamed: "user")
    )
    XCTAssertEqual(session, expectedSession)
  }

  func testSessionFromURLWithMissingComponent() async {
    let url = URL(
      string:
      "https://dummy-url.com/callback#access_token=accesstoken&expires_in=60&refresh_token=refreshtoken"
    )!

    do {
      _ = try await sut.session(from: url)
    } catch let error as URLError {
      XCTAssertEqual(error.code, .badURL)
    } catch {
      XCTFail("Unexpected error thrown: \(error.localizedDescription)")
    }
  }
}
