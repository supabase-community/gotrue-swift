import AnyCodable
import Foundation

public struct User {
  public var id: String
  public var aud: String
  public var role: String
  public var email: String
  public var emailConfirmedAt: Date?
  public var invitedAt: Date?
  public var phone: String
  public var phoneConfirmedAt: Date?
  public var confirmationSentAt: Date?
  public var recoverySentAt: Date?
  public var newEmail: String?
  public var emailChangeSentAt: Date?
  public var newPhone: String?
  public var phoneChangeSentAt: Date?
  public var lastSignInAt: Date?
  public var appMetadata: [String: Any]
  public var userMetadata: [String: Any]
  public var identities: [Identity]
  public var createdAt: Date
  public var updatedAt: Date

  public struct Identity: Codable {
    public let id: String
    public let userID: String
    public let identityData: [String: Any]?
    public let provider: String
    public let lastSignInAt: Date?
    public let createdAt: Date
    public let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
      case id
      case userID = "user_id"
      case identityData = "identity_data"
      case provider
      case lastSignInAt = "last_sign_in_at"
      case createdAt = "created_at"
      case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      id = try container.decode(String.self, forKey: .id)
      userID = try container.decode(String.self, forKey: .userID)
      identityData = try container.decodeIfPresent(
        [String: AnyDecodable].self, forKey: .identityData)?.mapValues(\.value)
      provider = try container.decode(String.self, forKey: .provider)
      lastSignInAt = try container.decodeIfPresent(Date.self, forKey: .lastSignInAt)
      createdAt = try container.decode(Date.self, forKey: .createdAt)
      updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(userID, forKey: .userID)
      try container.encodeIfPresent(
        identityData?.mapValues(AnyEncodable.init), forKey: .identityData)
      try container.encode(provider, forKey: .provider)
      try container.encodeIfPresent(lastSignInAt, forKey: .lastSignInAt)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
    }
  }
}

extension User: Codable {
  private enum CodingKeys: String, CodingKey {
    case id
    case aud
    case role
    case email
    case emailConfirmedAt = "email_confirmed_at"
    case invitedAt = "invited_at"
    case phone
    case phoneConfirmedAt = "phone_confirmed_at"
    case confirmationSentAt = "confirmation_sent_at"
    case recoverySentAt = "recovery_sent_at"
    case newEmail = "new_email"
    case emailChangeSentAt = "email_change_sent_at"
    case newPhone = "new_phone"
    case phoneChangeSentAt = "phone_change_sent_at"
    case lastSignInAt = "last_sign_in_at"
    case appMetadata = "app_metadata"
    case userMetadata = "user_metadata"
    case identities
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    aud = try container.decode(String.self, forKey: .aud)
    role = try container.decode(String.self, forKey: .role)
    email = try container.decode(String.self, forKey: .email)
    emailConfirmedAt = try container.decodeIfPresent(Date.self, forKey: .emailConfirmedAt)
    invitedAt = try container.decodeIfPresent(Date.self, forKey: .invitedAt)
    phone = try container.decode(String.self, forKey: .phone)
    phoneConfirmedAt = try container.decodeIfPresent(Date.self, forKey: .phoneConfirmedAt)
    confirmationSentAt = try container.decodeIfPresent(Date.self, forKey: .confirmationSentAt)
    recoverySentAt = try container.decodeIfPresent(Date.self, forKey: .recoverySentAt)
    newEmail = try container.decodeIfPresent(String.self, forKey: .newEmail)
    emailChangeSentAt = try container.decodeIfPresent(Date.self, forKey: .emailChangeSentAt)
    newPhone = try container.decodeIfPresent(String.self, forKey: .newPhone)
    phoneChangeSentAt = try container.decodeIfPresent(Date.self, forKey: .phoneChangeSentAt)
    lastSignInAt = try container.decodeIfPresent(Date.self, forKey: .lastSignInAt)
    appMetadata = try container.decode([String: AnyDecodable].self, forKey: .appMetadata).mapValues(
      \.value)
    userMetadata = try container.decode([String: AnyDecodable].self, forKey: .userMetadata)
      .mapValues(\.value)
    identities = try container.decode([Identity].self, forKey: .identities)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    updatedAt = try container.decode(Date.self, forKey: .updatedAt)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(aud, forKey: .aud)
    try container.encode(role, forKey: .role)
    try container.encode(email, forKey: .email)
    try container.encodeIfPresent(emailConfirmedAt, forKey: .emailConfirmedAt)
    try container.encodeIfPresent(invitedAt, forKey: .invitedAt)
    try container.encode(phone, forKey: .phone)
    try container.encodeIfPresent(phoneConfirmedAt, forKey: .phoneConfirmedAt)
    try container.encodeIfPresent(confirmationSentAt, forKey: .confirmationSentAt)
    try container.encodeIfPresent(recoverySentAt, forKey: .recoverySentAt)
    try container.encodeIfPresent(newEmail, forKey: .newEmail)
    try container.encodeIfPresent(emailChangeSentAt, forKey: .emailChangeSentAt)
    try container.encodeIfPresent(newPhone, forKey: .newPhone)
    try container.encodeIfPresent(phoneChangeSentAt, forKey: .phoneChangeSentAt)
    try container.encodeIfPresent(lastSignInAt, forKey: .lastSignInAt)
    try container.encode(appMetadata.mapValues(AnyEncodable.init), forKey: .appMetadata)
    try container.encode(userMetadata.mapValues(AnyEncodable.init), forKey: .userMetadata)
    try container.encode(identities, forKey: .identities)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(updatedAt, forKey: .updatedAt)
  }
}
