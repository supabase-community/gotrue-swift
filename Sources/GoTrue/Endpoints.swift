import Foundation
import Get
import URLQueryEncoder

enum Paths {}

extension Paths {
  static var token: Token {
    Token(path: "/token")
  }

  struct Token {
    /// Path: `/token`
    let path: String

    func post(
      grantType: GrantType,
      redirectTo: URL? = nil,
      _ body: PostRequest
    ) -> Request<GoTrue.Session> {
      Request(method: "POST", url: path, query: makePostQuery(grantType, redirectTo), body: body)
    }

    private func makePostQuery(_ grantType: GrantType, _ redirectTo: URL?) -> [(String, String?)] {
      let encoder = URLQueryEncoder()
      encoder.encode(grantType, forKey: "grant_type")
      encoder.encode(redirectTo, forKey: "redirect_to")
      return encoder.items
    }

    enum GrantType: String, Codable, CaseIterable {
      case password
      case refreshToken = "refresh_token"
      case idToken = "id_token"
    }

    enum PostRequest: Encodable, Equatable {
      case userCredentials(GoTrue.UserCredentials)
      case openIDConnectCredentials(GoTrue.OpenIDConnectCredentials)

      func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .userCredentials(value): try container.encode(value)
        case let .openIDConnectCredentials(value): try container.encode(value)
        }
      }
    }
  }
}

extension Paths {
  static var signup: Signup {
    Signup(path: "/signup")
  }

  struct Signup {
    /// Path: `/signup`
    let path: String

    func post(
      redirectTo: URL? = nil,
      _ body: GoTrue.SignUpRequest
    ) -> Request<GoTrue.AuthResponse> {
      Request(method: "POST", url: path, query: makePostQuery(redirectTo), body: body)
    }

    private func makePostQuery(_ redirectTo: URL?) -> [(String, String?)] {
      let encoder = URLQueryEncoder()
      encoder.encode(redirectTo, forKey: "redirect_to")
      return encoder.items
    }
  }
}

extension Paths {
  static var otp: Otp {
    Otp(path: "/otp")
  }

  struct Otp {
    /// Path: `/otp`
    let path: String

    func post(redirectTo: URL? = nil, _ body: GoTrue.OTPParams) -> Request<Void> {
      Request(method: "POST", url: path, query: makePostQuery(redirectTo), body: body)
    }

    private func makePostQuery(_ redirectTo: URL?) -> [(String, String?)] {
      let encoder = URLQueryEncoder()
      encoder.encode(redirectTo, forKey: "redirect_to")
      return encoder.items
    }
  }
}

extension Paths {
  static var verify: Verify {
    Verify(path: "/verify")
  }

  struct Verify {
    /// Path: `/verify`
    let path: String

    func post(
      redirectTo: URL? = nil,
      _ body: GoTrue.VerifyOTPParams
    ) -> Request<GoTrue.AuthResponse> {
      Request(method: "POST", url: path, query: makePostQuery(redirectTo), body: body)
    }

    private func makePostQuery(_ redirectTo: URL?) -> [(String, String?)] {
      let encoder = URLQueryEncoder()
      encoder.encode(redirectTo, forKey: "redirect_to")
      return encoder.items
    }
  }
}

extension Paths {
  static var user: User {
    User(path: "/user")
  }

  struct User {
    /// Path: `/user`
    let path: String

    var get: Request<GoTrue.User> {
      Request(method: "GET", url: path)
    }

    func put(_ body: GoTrue.UserAttributes) -> Request<GoTrue.User> {
      Request(method: "PUT", url: path, body: body)
    }
  }
}

extension Paths {
  static var logout: Logout {
    Logout(path: "/logout")
  }

  struct Logout {
    /// Path: `/logout`
    let path: String

    var post: Request<Void> {
      Request(method: "POST", url: path)
    }
  }
}

extension Paths {
  static var recover: Recover {
    Recover(path: "/recover")
  }

  struct Recover {
    /// Path: `/recover`
    let path: String

    func post(redirectTo: URL? = nil, _ body: GoTrue.RecoverParams) -> Request<Void> {
      Request(method: "POST", url: path, query: makePostQuery(redirectTo), body: body)
    }

    private func makePostQuery(_ redirectTo: URL?) -> [(String, String?)] {
      let encoder = URLQueryEncoder()
      encoder.encode(redirectTo, forKey: "redirect_to")
      return encoder.items
    }
  }
}
