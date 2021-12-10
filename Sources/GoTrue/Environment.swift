import Foundation
import XCTestDynamicOverlay
import SimpleHTTP

struct Environment {
    var url: () -> URL
    var httpClient: HTTPClientProtocol
    var api: GoTrueApi
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
            api: GoTrueApi(),
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
            api: GoTrueApi(),
            sessionStorage: .noop,
            sessionManager: .noop
        )
    }
}
#endif
