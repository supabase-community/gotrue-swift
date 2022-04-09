import XCTest

@testable import GoTrue

@available(iOS 13.0.0, macOS 10.15, tvOS 13.0, *)
final class IntegrationTests: XCTestCase {
  var apikey: String {
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24ifQ.625_WdcF3KHqz5amU0x2X5WWHP-OEs_4qj0ssLNHzTs"
  }

  var gotrueURL: URL {
    URL(string: "http://localhost:54321/auth/v1")!
  }

  func test_signUpWithEmailAndPassword() async throws {
    try XCTSkipIf(
      ProcessInfo.processInfo.environment["INTEGRATION_TESTS"] == nil,
      "INTEGRATION_TESTS not defined.")

    let client = GoTrueClient(url: gotrueURL, headers: ["apikey": apikey])

    let user = try await client.signUp(email: "sample@supabase.io", password: "qwerty123").user
    XCTAssertEqual(try XCTUnwrap(user).email, "sample@supabase.io")
  }
}
