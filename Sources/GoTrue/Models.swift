import AnyCodable
import Foundation

// MARK: - SignUpOptions
public struct SignUpOptions {
  public let redirectTo: URL?
  public let data: AnyEncodable?

  public init(redirectTo: URL? = nil, data: AnyEncodable? = nil) {
    self.redirectTo = redirectTo
    self.data = data
  }
}

// MARK: - AuthChangeEvent
public enum AuthChangeEvent: String {
  case signedIn = "SIGNED_IN"
  case signedOut = "SIGNED_OUT"
  case userUpdated = "USER_UPDATED"
  case userDeleted = "USER_DELETED"
  case passwordRecovery = "PASSWORD_RECOVERY"
}

// MARK: - Provider
public enum Provider: String {
  case apple
  case azure
  case bitbucket
  case discord
  case facebook
  case github
  case gitlab
  case google
  case slack
  case spotify
  case twitter
}

public struct ProviderOptions {
  public var redirectTo: String?
  public var scopes: String?

  public init(redirectTo: String?, scopes: String?) {
    self.redirectTo = redirectTo
    self.scopes = scopes
  }
}

// MARK: - Session
public struct Session: Codable, Equatable {
  public let accessToken: String
  public let tokenType: String
  public let expiresIn: Int
  public let refreshToken: String
  public let providerToken: String?
  public internal(set) var user: User

  var expireAt: Date

  internal var isValid: Bool {
    Date() < expireAt
  }

  internal init(
    accessToken: String, tokenType: String, expiresIn: Int, refreshToken: String,
    providerToken: String?, user: User, expireAt: Date? = nil
  ) {
    self.accessToken = accessToken
    self.tokenType = tokenType
    self.expiresIn = expiresIn
    self.refreshToken = refreshToken
    self.providerToken = providerToken
    self.user = user

    self.expireAt = expireAt ?? Date().addingTimeInterval(TimeInterval(expiresIn))
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let accessToken = try container.decode(String.self, forKey: .accessToken)
    let tokenType = try container.decode(String.self, forKey: .tokenType)
    let expiresIn = try container.decode(Int.self, forKey: .expiresIn)
    let refreshToken = try container.decode(String.self, forKey: .refreshToken)
    let providerToken = try container.decodeIfPresent(String.self, forKey: .providerToken)
    let user = try container.decode(User.self, forKey: .user)
    let expireAt = try container.decodeIfPresent(Date.self, forKey: .expireAt)

    self.init(
      accessToken: accessToken, tokenType: tokenType, expiresIn: expiresIn,
      refreshToken: refreshToken, providerToken: providerToken, user: user, expireAt: expireAt)
  }
}

#if DEBUG
  extension Session {
    static let dummy = Session(
      accessToken: "", tokenType: "", expiresIn: 0, refreshToken: "", providerToken: nil,
      user: .dummy)
  }
#endif

// MARK: - User
public struct User: Codable, Equatable {
  public internal(set) var id: String
  public let aud: String
  public let role: String
  public let email: String
  public let emailConfirmedAt: Date?
  public let phone: String
  public let phoneConfirmedAt: Date?
  public let confirmationSentAt: Date?
  public let confirmedAt: Date?
  public let lastSignInAt: Date?
  public let appMetadata: [String: AnyCodable]?
  public let userMetadata: [String: AnyCodable]?
  public let createdAt: Date
  public let updatedAt: Date
}

#if DEBUG
  extension User {
    static let dummy = User(
      id: "", aud: "", role: "", email: "", emailConfirmedAt: nil, phone: "", phoneConfirmedAt: nil,
      confirmationSentAt: nil, confirmedAt: nil, lastSignInAt: nil, appMetadata: nil,
      userMetadata: nil, createdAt: Date(), updatedAt: Date())
  }
#endif

// MARK: - UpdateUserParams
public struct UpdateUserParams: Encodable {
  public var emailChangeToken: String?
  public var password: String?
  public var data: [String: AnyEncodable]?

  public init(
    emailChangeToken: String? = nil,
    password: String? = nil,
    data: [String: AnyEncodable]? = nil
  ) {
    self.emailChangeToken = emailChangeToken
    self.password = password
    self.data = data
  }
}
