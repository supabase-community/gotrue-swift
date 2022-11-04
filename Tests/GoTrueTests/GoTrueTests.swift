import Mocker
import XCTest

@testable import GoTrue

actor InMemoryLocalStorage: GoTrueLocalStorage {
  private var storage: [String: Data] = [:]

  func store(key: String, value: Data) async throws {
    storage[key] = value
  }

  func retrieve(key: String) async throws -> Data? {
    storage[key]
  }

  func remove(key: String) async throws {
    storage[key] = nil
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

  func testDecodeSessionOrUser() {
    XCTAssertNoThrow(
      try JSONDecoder.goTrue.decode(
        AuthResponse.self, from: sessionJSON.data(using: .utf8)!
      )
    )
  }

  #if !os(watchOS)
    // Not working on watchOS, don't know why.
    func test_signUpWithEmailAndPassword() async throws {
      Mock.post(path: "signup", json: "signup-response").register()

      let user = try await sut.signUp(email: "guilherme@grds.dev", password: "thepass").user

      XCTAssertEqual(user?.email, "guilherme@grds.dev")
    }
  #endif

  func testSignInWithProvider() throws {
    let url = try sut.getOAuthSignInURL(
      provider: .github, scopes: "read,write",
      redirectURL: URL(string: "https://dummy-url.com/redirect")!,
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
    mock.onRequest = { urlRequest, _ in
      let authorizationHeader = urlRequest.allHTTPHeaderFields?["Authorization"]
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

let sessionJSON = """
{
"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjQ4NjQwMDIxLCJzdWIiOiJmMzNkM2VjOS1hMmVlLTQ3YzQtODBlMS01YmQ5MTlmM2Q4YjgiLCJlbWFpbCI6Imd1aWxoZXJtZTJAZ3Jkcy5kZXYiLCJwaG9uZSI6IiIsImFwcF9tZXRhZGF0YSI6eyJwcm92aWRlciI6ImVtYWlsIiwicHJvdmlkZXJzIjpbImVtYWlsIl19LCJ1c2VyX21ldGFkYXRhIjp7fSwicm9sZSI6ImF1dGhlbnRpY2F0ZWQifQ.4lMvmz2pJkWu1hMsBgXP98Fwz4rbvFYl4VA9joRv6kY",
"token_type": "bearer",
"expires_in": 3600,
"refresh_token": "GGduTeu95GraIXQ56jppkw",
"user": {
"id": "f33d3ec9-a2ee-47c4-80e1-5bd919f3d8b8",
"aud": "authenticated",
"role": "authenticated",
"email": "guilherme2@grds.dev",
"email_confirmed_at": "2022-03-30T10:33:41.018575157Z",
"phone": "",
"last_sign_in_at": "2022-03-30T10:33:41.021531328Z",
"app_metadata": {
"provider": "email",
"providers": [
"email"
]
},
"user_metadata": {},
"identities": [
{
"id": "f33d3ec9-a2ee-47c4-80e1-5bd919f3d8b8",
"user_id": "f33d3ec9-a2ee-47c4-80e1-5bd919f3d8b8",
"identity_data": {
  "sub": "f33d3ec9-a2ee-47c4-80e1-5bd919f3d8b8"
},
"provider": "email",
"last_sign_in_at": "2022-03-30T10:33:41.015557063Z",
"created_at": "2022-03-30T10:33:41.015612Z",
"updated_at": "2022-03-30T10:33:41.015616Z"
}
],
"created_at": "2022-03-30T10:33:41.005433Z",
"updated_at": "2022-03-30T10:33:41.022688Z"
}
}
"""
