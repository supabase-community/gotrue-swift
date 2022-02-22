import Foundation

public struct Session: Codable {
  public let accessToken: String
  public let tokenType: String
  public let expiresIn: TimeInterval
  public let refreshToken: String
  public var user: User

  var expiresAt: Date

  public init(
    accessToken: String,
    tokenType: String,
    expiresIn: TimeInterval,
    refreshToken: String,
    user: User
  ) {
    self.accessToken = accessToken
    self.tokenType = tokenType
    self.expiresIn = expiresIn
    self.refreshToken = refreshToken
    self.user = user

    self.expiresAt = Date().addingTimeInterval(self.expiresIn)
  }

  private enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case tokenType = "token_type"
    case expiresIn = "expires_in"
    case refreshToken = "refresh_token"
    case user

    case expiresAt = "expires_at"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.accessToken = try container.decode(String.self, forKey: .accessToken)
    self.tokenType = try container.decode(String.self, forKey: .tokenType)
    self.expiresIn = try container.decode(TimeInterval.self, forKey: .expiresIn)
    self.refreshToken = try container.decode(String.self, forKey: .refreshToken)
    self.user = try container.decode(User.self, forKey: .user)

    self.expiresAt =
      try container.decodeIfPresent(Date.self, forKey: .expiresAt)
      ?? Date().addingTimeInterval(self.expiresIn)
  }

  public var isValid: Bool {
    // Consider a session expired 1min before its real expire date.
    expiresAt.addingTimeInterval(-60) > Date()
  }
}
