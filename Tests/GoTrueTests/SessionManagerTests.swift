import XCTest

@testable import GoTrue

final class SessionManagerTests: XCTestCase {
  let sut = SessionManager.live

  override func setUp() {
    super.setUp()
    Env = .failing
  }

  func testRemoveSession() async {
    Env.sessionStorage.delete = {
      XCTAssertTrue(true)
    }

    await sut.removeSession()
  }

  func testUpdateSession() async {
    Env.sessionStorage.store = { session in
      XCTAssertEqual(session, .dummy)
    }

    await sut.updateSession(.dummy)
  }

  func testUpdateUser() async {
    var user = User.dummy
    user.id = UUID().uuidString

    Env.sessionStorage.get = { .dummy }
    Env.sessionStorage.store = { session in
      XCTAssertEqual(session.user, user)
    }

    await sut.updateUser(user)
  }
}
