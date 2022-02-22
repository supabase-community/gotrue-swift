import XCTest

@testable import GoTrue

final class IntegrationTests: XCTestCase {
  let gotrue = GoTrueClient(url: gotrueURL(), headers: ["apikey": apikey()], autoRefreshToken: true)

  static func apikey() -> String {
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24ifQ.625_WdcF3KHqz5amU0x2X5WWHP-OEs_4qj0ssLNHzTs"
  }

  static func gotrueURL() -> String {
    "http://localhost:54321/auth/v1"
  }

  func test_signUpWithEmailAndPassword() {
    let expectation = self.expectation(description: #function)

    gotrue.signUp(email: "sample@supabase.io", password: "qwerty123") { result in
      switch result {
      case .failure(let error):
        XCTFail("\(#function) failed with error: \(dump(error))")
      case .success(let user):
        XCTAssertEqual(user.email, "sample@supabase.io")
      }

      expectation.fulfill()
    }

    waitForExpectations(timeout: 3) { error in
      if let error = error {
        XCTFail("\(#function) failed: \(error.localizedDescription)")
      }
    }
  }
}
