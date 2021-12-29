import Foundation
import XCTestDynamicOverlay

#if DEBUG
  extension API {
    static var failing: API {
      API(
        signUpWithEmail: { _, _, _ in
          XCTFail("API.signUpWithEmail was not implemented.")
          return .dummy
        },
        signInWithEmail: { _, _, _ in
          XCTFail("API.signInWithEmail was not implemented.")
          return .dummy
        },
        signUpWithPhone: { _, _, _ in
          XCTFail("API.signUpWithPhone was not implemented.")
          return .dummy
        },
        signInWithPhone: { _, _ in
          XCTFail("API.signInWithPhone was not implemented.")
          return .dummy
        },
        sendMagicLinkEmail: { _, _ in
          XCTFail("API.sendMagicLinkEmail was not implemented.")
        },
        sendMobileOTP: { _ in
          XCTFail("API.sendMobileOTP was not implemented.")
        },
        verifyMobileOTP: { _, _, _ in
          XCTFail("API.verifyMobileOTP was not implemented.")
          return .dummy
        },
        inviteUserByEmail: { _, _ in
          XCTFail("API.inviteUserByEmail was not implemented.")
          return .dummy
        },
        resetPasswordForEmail: { _, _ in
          XCTFail("API.resetPasswordForEmail was not implemented.")
        },
        getUrlForProvider: { _, _ in
          XCTFail("API.getUrlForProvider was not implemented.")
          return URL(string: "https://test.com")!
        },
        refreshAccessToken: { _ in
          XCTFail("API.refreshAccessToken was not implemented.")
          return .dummy
        },
        signOut: {
          XCTFail("API.signOut was not implemented.")
        },
        updateUser: { _ in
          XCTFail("API.updateUser was not implemented.")
          return .dummy
        },
        getUser: {
          XCTFail("API.getUser was not implemented.")
          return .dummy
        }
      )
    }

    static var noop: API {
      API(
        signUpWithEmail: { _, _, _ in
          return .dummy
        },
        signInWithEmail: { _, _, _ in
          return .dummy
        },
        signUpWithPhone: { _, _, _ in
          return .dummy
        },
        signInWithPhone: { _, _ in
          return .dummy
        },
        sendMagicLinkEmail: { _, _ in
        },
        sendMobileOTP: { _ in
        },
        verifyMobileOTP: { _, _, _ in
          return .dummy
        },
        inviteUserByEmail: { _, _ in
          return .dummy
        },
        resetPasswordForEmail: { _, _ in
        },
        getUrlForProvider: { _, _ in
          return URL(string: "https://test.com")!
        },
        refreshAccessToken: { _ in
          return .dummy
        },
        signOut: {
        },
        updateUser: { _ in
          return .dummy
        },
        getUser: {
          return .dummy
        }
      )
    }
  }
#endif
