@testable import GoTrue
import XCTest

final class GoTrueTests: XCTestCase {
    let gotrue = GoTrueClient(url: gotrueURL(), headers: ["apikey": apikey()], autoRefreshToken: true)

    static func apikey() -> String {
        if let token = ProcessInfo.processInfo.environment["apikey"] {
            return token
        } else {
            fatalError()
        }
    }

    static func gotrueURL() -> String {
        if let url = ProcessInfo.processInfo.environment["GoTrueURL"] {
            return url
        } else {
            fatalError()
        }
    }

    func testSignIN() {
        let e = expectation(description: "testSignIN")

        gotrue.signIn(email: "sample@mail.com", password: "secret") { result in
            switch result {
            case let .success(session):
                print(session)
                XCTAssertNotNil(session.accessToken)
            case let .failure(error):
                print(error.localizedDescription)
                XCTFail("testSignIN failed: \(error.localizedDescription)")
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 30) { error in
            if let error = error {
                XCTFail("testSignIN failed: \(error.localizedDescription)")
            }
        }
    }

    static var allTests = [
        ("testSignIN", testSignIN),
    ]
}
