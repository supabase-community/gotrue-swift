import AnyCodable
import Foundation

public struct User: Codable {
  public let id: String
  public let aud: String
  public let role: String
  public let email: String
  public let emailConfirmedAt: Date?
  public let phone: String
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
      id: "", aud: "", role: "", email: "", emailConfirmedAt: nil, phone: "",
      confirmationSentAt: nil, confirmedAt: nil, lastSignInAt: nil, appMetadata: nil,
      userMetadata: nil, createdAt: Date(), updatedAt: Date())
  }
#endif

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
