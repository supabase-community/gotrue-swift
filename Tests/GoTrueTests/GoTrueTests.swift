import SnapshotTesting
import SimpleHTTP
import XCTest

@testable import GoTrue

final class GoTrueTests: XCTestCase {
    override func setUp() {
//        Env = Environment(
//            url: URL(string: "https://localhost/auth/v1")!,
//            httpClient: HTTPClient.failing,
//            httpClient: World.HTTP(
//                send: { request in
//                    if let invocation = self.invocation {
//                        let testName = "\(invocation.selector)"
//                        assertSnapshot(matching: request, as: .curl, testName: testName)
//                    }
//
//                    return Response(
//                        data: Data(),
//                        httpResponse: HTTPURLResponse(
//                            url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil
//                        )!
//                    )
//                }
//            ),
//            api: GoTrueApi(),
//            sessionStorage: .failing,
//            sessionManager: .failing
//            authenticator: {
//                $0.setValue(
//                    "Bearer 027cbf6b-3803-4016-8c29-70b5c74c19d2", forHTTPHeaderField: "Authorization"
//                )
//            }
//        )

        Env = .failing
    }

    func testSignIn() async {
        _ = try? await Env.api.signInWithEmail(email: "test@test.com", password: "test1234")
    }

    func testSignUpWithEmail() async {
        _ = try? await Env.api.signUpWithEmail(email: "test@test.com", password: "test1234")
    }

    func testSendMagicLink() async {
        try? await Env.api.sendMagicLinkEmail(email: "test@test.com")
    }

    func testRefreshAccessToken() async {
        _ = try? await Env.api.refreshAccessToken(refreshToken: "027cbf6b-3803-4016-8c29-70b5c74c19d2")
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
