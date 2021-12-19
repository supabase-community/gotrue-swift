import Foundation

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
