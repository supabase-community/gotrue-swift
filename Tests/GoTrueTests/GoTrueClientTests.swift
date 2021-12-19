import XCTest

@testable import GoTrue

final class GoTrueClientTests: XCTestCase {
  lazy var sut = GoTrueClient(
    url: URL(string: "https://localhost/auth/v1")!,
    apiKey:
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
  )

  override func setUp() {
    super.setUp()
    Env = .failing
  }
}
