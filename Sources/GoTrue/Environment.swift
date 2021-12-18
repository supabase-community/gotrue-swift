import Foundation
import SimpleHTTP
import XCTestDynamicOverlay

struct Environment {
  var url: () -> URL
  var httpClient: HTTPClientProtocol
  var sessionStorage: SessionStorage
  var sessionManager: SessionManager
}

var Env: Environment!

#if DEBUG
  extension Environment {
    static var failing: Environment {
      Environment(
        url: {
          XCTFail("Environment.url() called but was not implemented.")
          return URL(string: "https://example.com")!
        },
        httpClient: HTTPClient.failing,
        sessionStorage: .failing,
        sessionManager: .failing
      )
    }

    static var noop: Environment {
      Environment(
        url: {
          URL(string: "https://example.com")!
        },
        httpClient: HTTPClient.noop,
        sessionStorage: .noop,
        sessionManager: .noop
      )
    }
  }
#endif
