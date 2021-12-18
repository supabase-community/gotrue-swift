import SimpleHTTP
import SnapshotTesting
import XCTest

@testable import GoTrue

final class GoTrueTests: XCTestCase {

  let apiKey =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
  let refreshToken =
    "eyJhbGciOiJSUzM4NCIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.o1hC1xYbJolSyh0-bOY230w22zEQSk5TiBfc-OCvtpI2JtYlW-23-8B48NpATozzMHn0j3rE0xVUldxShzy0xeJ7vYAccVXu2Gs9rnTVqouc-UZu_wJHkZiKBL67j8_61L6SXswzPAQu4kVDwAefGf5hyYBUM-80vYZwWPEpLI8K4yCBsF6I9N1yQaZAJmkMp_Iw371Menae4Mp4JusvBJS-s6LrmG2QbiZaFaxVJiW8KlUkWyUCns8-qFl5OMeYlgGFsyvvSHvXCzQrsEXqyCdS4tQJd73ayYA4SPtCb9clz76N1zE5WsV4Z0BYrxeb77oA7jJhh994RAPzCG0hmQ"

  override func setUp() {
    Env = .failing

    Env.url = { URL(string: "https://localhost/auth/v1")! }
    Env.httpClient = HTTPClient.goTrueClient(url: Env.url(), apiKey: apiKey)
    Env.sessionManager.session = {
      Session(
        accessToken:
          "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.VFb0qJ1LRg_4ujbZoRMXnVkUgiuKq5KxWqNdbKq_G9Vvz-S1zZa9LPxtHWKa64zDl2ofkT8F6jBt_K4riU-fPg",
        tokenType: "bearer", expiresIn: 3600, refreshToken: self.refreshToken, providerToken: nil,
        user: User.dummy)
    }

    SimpleHTTP.Current.session.request = { request in
      if let invocation = self.invocation {
        let testName = "\(invocation.selector)"
        assertSnapshot(matching: request, as: .curl, testName: testName)
      }

      return (
        Data(),
        HTTPURLResponse(
          url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil
        )!
      )
    }
  }

  func testSignIn() async {
    _ = try? await Env.api.signInWithEmail(email: "test@test.com", password: "test1234")
  }

  func testSignUpWithEmail() async {
    _ = try? await Env.api.signUpWithEmail(
      email: "test@test.com", password: "test1234", options: SignUpOptions())
  }

  func testSendMagicLink() async {
    try? await Env.api.sendMagicLinkEmail(
      email: "test@test.com", redirectTo: URL(string: "gotrue-swift://verify-email?token=deadbeef"))
  }

  func testRefreshAccessToken() async {
    _ = try? await Env.api.refreshAccessToken(refreshToken: refreshToken)
  }

  func testSignOut() async {
    _ = try? await Env.api.signOut()
  }

  func testUpdateUser() async {
    _ = try? await Env.api.updateUser(
      params: UpdateUserParams(
        emailChangeToken: "26a0bab5-17f5-43cb-8bd5-384e5a44003e",
        password: "new.pass.1234",
        data: ["dummyData": 42]
      )
    )
  }

  func testGetUser() async {
    _ = try? await Env.api.getUser()
  }
}

final class HTTPClientMock: HTTPClientProtocol {

  var requestHandler: (_ endpoint: Endpoint) async throws -> Response

  init(requestHandler: @escaping (_ endpoint: Endpoint) async throws -> Response) {
    self.requestHandler = requestHandler
  }

  func request(_ endpoint: Endpoint) async throws -> Response {
    try await requestHandler(endpoint)
  }
}
