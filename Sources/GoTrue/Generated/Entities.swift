// Generated by Create API
// https://github.com/CreateAPI/CreateAPI

import Foundation

public enum AnyJSON: Equatable, Codable {
  case string(String)
  case number(Double)
  case object([String: AnyJSON])
  case array([AnyJSON])
  case bool(Bool)

  var value: Any {
    switch self {
    case let .string(string): return string
    case let .number(double): return double
    case let .object(dictionary): return dictionary
    case let .array(array): return array
    case let .bool(bool): return bool
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case let .array(array): try container.encode(array)
    case let .object(object): try container.encode(object)
    case let .string(string): try container.encode(string)
    case let .number(number): try container.encode(number)
    case let .bool(bool): try container.encode(bool)
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let object = try? container.decode([String: AnyJSON].self) {
      self = .object(object)
    } else if let array = try? container.decode([AnyJSON].self) {
      self = .array(array)
    } else if let string = try? container.decode(String.self) {
      self = .string(string)
    } else if let bool = try? container.decode(Bool.self) {
      self = .bool(bool)
    } else if let number = try? container.decode(Double.self) {
      self = .number(number)
    } else {
      throw DecodingError.dataCorrupted(
        .init(codingPath: decoder.codingPath, debugDescription: "Invalid JSON value.")
      )
    }
  }
}

struct StringCodingKey: CodingKey, ExpressibleByStringLiteral {
  private let string: String
  private var int: Int?

  var stringValue: String { string }

  init(string: String) {
    self.string = string
  }

  init?(stringValue: String) {
    string = stringValue
  }

  var intValue: Int? { int }

  init?(intValue: Int) {
    string = String(describing: intValue)
    int = intValue
  }

  init(stringLiteral value: String) {
    string = value
  }
}

public struct UserCredentials: Codable, Equatable {
  public var email: String?
  public var password: String?
  public var phone: String?
  public var refreshToken: String?

  public init(
    email: String? = nil,
    password: String? = nil,
    phone: String? = nil,
    refreshToken: String? = nil
  ) {
    self.email = email
    self.password = password
    self.phone = phone
    self.refreshToken = refreshToken
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: StringCodingKey.self)
    email = try values.decodeIfPresent(String.self, forKey: "email")
    password = try values.decodeIfPresent(String.self, forKey: "password")
    phone = try values.decodeIfPresent(String.self, forKey: "phone")
    refreshToken = try values.decodeIfPresent(String.self, forKey: "refresh_token")
  }

  public func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: StringCodingKey.self)
    try values.encodeIfPresent(email, forKey: "email")
    try values.encodeIfPresent(password, forKey: "password")
    try values.encodeIfPresent(phone, forKey: "phone")
    try values.encodeIfPresent(refreshToken, forKey: "refresh_token")
  }
}

public struct SignUpRequest: Codable, Equatable {
  public var email: String?
  public var password: String?
  public var phone: String?
  public var data: [String: AnyJSON]?
  public var gotrueMetaSecurity: GoTrueMetaSecurity?

  public init(
    email: String? = nil,
    password: String? = nil,
    phone: String? = nil,
    data: [String: AnyJSON]? = nil,
    gotrueMetaSecurity: GoTrueMetaSecurity? = nil
  ) {
    self.email = email
    self.password = password
    self.phone = phone
    self.data = data
    self.gotrueMetaSecurity = gotrueMetaSecurity
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: StringCodingKey.self)
    email = try values.decodeIfPresent(String.self, forKey: "email")
    password = try values.decodeIfPresent(String.self, forKey: "password")
    phone = try values.decodeIfPresent(String.self, forKey: "phone")
    data = try values.decodeIfPresent([String: AnyJSON].self, forKey: "data")
    gotrueMetaSecurity = try values.decodeIfPresent(
      GoTrueMetaSecurity.self,
      forKey: "gotrue_meta_security"
    )
  }

  public func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: StringCodingKey.self)
    try values.encodeIfPresent(email, forKey: "email")
    try values.encodeIfPresent(password, forKey: "password")
    try values.encodeIfPresent(phone, forKey: "phone")
    try values.encodeIfPresent(data, forKey: "data")
    try values.encodeIfPresent(gotrueMetaSecurity, forKey: "gotrue_meta_security")
  }
}

public struct Session: Codable, Equatable {
  /// The oauth provider token. If present, this can be used to make external API requests to the
  /// oauth provider used.
  public var providerToken: String?
  /// The oauth provider refresh token. If present, this can be used to refresh the provider_token
  /// via the oauth provider's API. Not all oauth providers return a provider refresh token. If the
  /// provider_refresh_token is missing, please refer to the oauth provider's documentation for
  /// information on how to obtain the provider refresh token.
  public var providerRefreshToken: String?
  /// The access token jwt. It is recommended to set the JWT_EXPIRY to a shorter expiry value.
  public var accessToken: String
  public var tokenType: String
  /// The number of seconds until the token expires (since it was issued). Returned when a login is
  /// confirmed.
  public var expiresIn: Double
  /// A one-time used refresh token that never expires.
  public var refreshToken: String
  public var user: User

  public init(
    providerToken: String? = nil,
    providerRefreshToken: String? = nil,
    accessToken: String,
    tokenType: String,
    expiresIn: Double,
    refreshToken: String,
    user: User
  ) {
    self.providerToken = providerToken
    self.providerRefreshToken = providerRefreshToken
    self.accessToken = accessToken
    self.tokenType = tokenType
    self.expiresIn = expiresIn
    self.refreshToken = refreshToken
    self.user = user
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: StringCodingKey.self)
    providerToken = try values.decodeIfPresent(String.self, forKey: "provider_token")
    providerRefreshToken = try values.decodeIfPresent(String.self, forKey: "provider_refresh_token")
    accessToken = try values.decode(String.self, forKey: "access_token")
    tokenType = try values.decode(String.self, forKey: "token_type")
    expiresIn = try values.decode(Double.self, forKey: "expires_in")
    refreshToken = try values.decode(String.self, forKey: "refresh_token")
    user = try values.decode(User.self, forKey: "user")
  }

  public func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: StringCodingKey.self)
    try values.encodeIfPresent(providerToken, forKey: "provider_token")
    try values.encodeIfPresent(providerRefreshToken, forKey: "provider_refresh_token")
    try values.encode(accessToken, forKey: "access_token")
    try values.encode(tokenType, forKey: "token_type")
    try values.encode(expiresIn, forKey: "expires_in")
    try values.encode(refreshToken, forKey: "refresh_token")
    try values.encode(user, forKey: "user")
  }
}

public struct User: Codable, Equatable, Identifiable {
  public var id: UUID
  public var appMetadata: [String: AnyJSON]
  public var userMetadata: [String: AnyJSON]
  public var aud: String
  public var confirmationSentAt: Date?
  public var recoverySentAt: Date?
  public var emailChangeSentAt: Date?
  public var newEmail: String?
  public var invitedAt: Date?
  public var actionLink: String?
  public var email: String?
  public var phone: String?
  public var createdAt: Date
  public var confirmedAt: Date?
  public var emailConfirmedAt: Date?
  public var phoneConfirmedAt: Date?
  public var lastSignInAt: Date?
  public var role: String?
  public var updatedAt: Date
  public var identities: [UserIdentity]?

  public init(
    id: UUID,
    appMetadata: [String: AnyJSON],
    userMetadata: [String: AnyJSON],
    aud: String,
    confirmationSentAt: Date? = nil,
    recoverySentAt: Date? = nil,
    emailChangeSentAt: Date? = nil,
    newEmail: String? = nil,
    invitedAt: Date? = nil,
    actionLink: String? = nil,
    email: String? = nil,
    phone: String? = nil,
    createdAt: Date,
    confirmedAt: Date? = nil,
    emailConfirmedAt: Date? = nil,
    phoneConfirmedAt: Date? = nil,
    lastSignInAt: Date? = nil,
    role: String? = nil,
    updatedAt: Date,
    identities: [UserIdentity]? = nil
  ) {
    self.id = id
    self.appMetadata = appMetadata
    self.userMetadata = userMetadata
    self.aud = aud
    self.confirmationSentAt = confirmationSentAt
    self.recoverySentAt = recoverySentAt
    self.emailChangeSentAt = emailChangeSentAt
    self.newEmail = newEmail
    self.invitedAt = invitedAt
    self.actionLink = actionLink
    self.email = email
    self.phone = phone
    self.createdAt = createdAt
    self.confirmedAt = confirmedAt
    self.emailConfirmedAt = emailConfirmedAt
    self.phoneConfirmedAt = phoneConfirmedAt
    self.lastSignInAt = lastSignInAt
    self.role = role
    self.updatedAt = updatedAt
    self.identities = identities
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: StringCodingKey.self)
    id = try values.decode(UUID.self, forKey: "id")
    appMetadata = try values.decode([String: AnyJSON].self, forKey: "app_metadata")
    userMetadata = try values.decode([String: AnyJSON].self, forKey: "user_metadata")
    aud = try values.decode(String.self, forKey: "aud")
    confirmationSentAt = try values.decodeIfPresent(Date.self, forKey: "confirmation_sent_at")
    recoverySentAt = try values.decodeIfPresent(Date.self, forKey: "recovery_sent_at")
    emailChangeSentAt = try values.decodeIfPresent(Date.self, forKey: "email_change_sent_at")
    newEmail = try values.decodeIfPresent(String.self, forKey: "new_email")
    invitedAt = try values.decodeIfPresent(Date.self, forKey: "invited_at")
    actionLink = try values.decodeIfPresent(String.self, forKey: "action_link")
    email = try values.decodeIfPresent(String.self, forKey: "email")
    phone = try values.decodeIfPresent(String.self, forKey: "phone")
    createdAt = try values.decode(Date.self, forKey: "created_at")
    confirmedAt = try values.decodeIfPresent(Date.self, forKey: "confirmed_at")
    emailConfirmedAt = try values.decodeIfPresent(Date.self, forKey: "email_confirmed_at")
    phoneConfirmedAt = try values.decodeIfPresent(Date.self, forKey: "phone_confirmed_at")
    lastSignInAt = try values.decodeIfPresent(Date.self, forKey: "last_sign_in_at")
    role = try values.decodeIfPresent(String.self, forKey: "role")
    updatedAt = try values.decode(Date.self, forKey: "updated_at")
    identities = try values.decodeIfPresent([UserIdentity].self, forKey: "identities")
  }

  public func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: StringCodingKey.self)
    try values.encode(id, forKey: "id")
    try values.encode(appMetadata, forKey: "app_metadata")
    try values.encode(userMetadata, forKey: "user_metadata")
    try values.encode(aud, forKey: "aud")
    try values.encodeIfPresent(confirmationSentAt, forKey: "confirmation_sent_at")
    try values.encodeIfPresent(recoverySentAt, forKey: "recovery_sent_at")
    try values.encodeIfPresent(emailChangeSentAt, forKey: "email_change_sent_at")
    try values.encodeIfPresent(newEmail, forKey: "new_email")
    try values.encodeIfPresent(invitedAt, forKey: "invited_at")
    try values.encodeIfPresent(actionLink, forKey: "action_link")
    try values.encodeIfPresent(email, forKey: "email")
    try values.encodeIfPresent(phone, forKey: "phone")
    try values.encode(createdAt, forKey: "created_at")
    try values.encodeIfPresent(confirmedAt, forKey: "confirmed_at")
    try values.encodeIfPresent(emailConfirmedAt, forKey: "email_confirmed_at")
    try values.encodeIfPresent(phoneConfirmedAt, forKey: "phone_confirmed_at")
    try values.encodeIfPresent(lastSignInAt, forKey: "last_sign_in_at")
    try values.encodeIfPresent(role, forKey: "role")
    try values.encode(updatedAt, forKey: "updated_at")
    try values.encodeIfPresent(identities, forKey: "identities")
  }
}

public struct UserIdentity: Codable, Equatable {
  public var id: String
  public var userID: UUID
  public var identityData: [String: AnyJSON]
  public var provider: String
  public var createdAt: Date
  public var lastSignInAt: Date
  public var updatedAt: Date

  public init(
    id: String,
    userID: UUID,
    identityData: [String: AnyJSON],
    provider: String,
    createdAt: Date,
    lastSignInAt: Date,
    updatedAt: Date
  ) {
    self.id = id
    self.userID = userID
    self.identityData = identityData
    self.provider = provider
    self.createdAt = createdAt
    self.lastSignInAt = lastSignInAt
    self.updatedAt = updatedAt
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: StringCodingKey.self)
    id = try values.decode(String.self, forKey: "id")
    userID = try values.decode(UUID.self, forKey: "user_id")
    identityData = try values.decode([String: AnyJSON].self, forKey: "identity_data")
    provider = try values.decode(String.self, forKey: "provider")
    createdAt = try values.decode(Date.self, forKey: "created_at")
    lastSignInAt = try values.decode(Date.self, forKey: "last_sign_in_at")
    updatedAt = try values.decode(Date.self, forKey: "updated_at")
  }

  public func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: StringCodingKey.self)
    try values.encode(id, forKey: "id")
    try values.encode(userID, forKey: "user_id")
    try values.encode(identityData, forKey: "identity_data")
    try values.encode(provider, forKey: "provider")
    try values.encode(createdAt, forKey: "created_at")
    try values.encode(lastSignInAt, forKey: "last_sign_in_at")
    try values.encode(updatedAt, forKey: "updated_at")
  }
}

public enum Provider: String, Codable, CaseIterable {
  case apple
  case azure
  case bitbucket
  case discord
  case email
  case facebook
  case github
  case gitlab
  case google
  case keycloak
  case linkedin
  case notion
  case slack
  case spotify
  case twitch
  case twitter
  case workos
}

public struct OpenIDConnectCredentials: Codable, Equatable {
  public var idToken: String
  public var nonce: String
  public var clientID: String?
  public var issuer: String?
  public var provider: Provider?

  public init(
    idToken: String,
    nonce: String,
    clientID: String? = nil,
    issuer: String? = nil,
    provider: Provider? = nil
  ) {
    self.idToken = idToken
    self.nonce = nonce
    self.clientID = clientID
    self.issuer = issuer
    self.provider = provider
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: StringCodingKey.self)
    idToken = try values.decode(String.self, forKey: "id_token")
    nonce = try values.decode(String.self, forKey: "nonce")
    clientID = try values.decodeIfPresent(String.self, forKey: "client_id")
    issuer = try values.decodeIfPresent(String.self, forKey: "issuer")
    provider = try values.decodeIfPresent(Provider.self, forKey: "provider")
  }

  public func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: StringCodingKey.self)
    try values.encode(idToken, forKey: "id_token")
    try values.encode(nonce, forKey: "nonce")
    try values.encodeIfPresent(clientID, forKey: "client_id")
    try values.encodeIfPresent(issuer, forKey: "issuer")
    try values.encodeIfPresent(provider, forKey: "provider")
  }
}

public struct GoTrueMetaSecurity: Codable, Equatable {
  public var hcaptchaToken: String

  public init(hcaptchaToken: String) {
    self.hcaptchaToken = hcaptchaToken
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: StringCodingKey.self)
    hcaptchaToken = try values.decode(String.self, forKey: "hcaptcha_token")
  }

  public func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: StringCodingKey.self)
    try values.encode(hcaptchaToken, forKey: "hcaptcha_token")
  }
}

public struct OTPParams: Codable, Equatable {
  public var email: String?
  public var phone: String?
  public var createUser: Bool
  public var data: [String: AnyJSON]?
  public var gotrueMetaSecurity: GoTrueMetaSecurity?

  public init(
    email: String? = nil,
    phone: String? = nil,
    createUser: Bool? = nil,
    data: [String: AnyJSON]? = nil,
    gotrueMetaSecurity: GoTrueMetaSecurity? = nil
  ) {
    self.email = email
    self.phone = phone
    self.createUser = createUser ?? true
    self.data = data
    self.gotrueMetaSecurity = gotrueMetaSecurity
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: StringCodingKey.self)
    email = try values.decodeIfPresent(String.self, forKey: "email")
    phone = try values.decodeIfPresent(String.self, forKey: "phone")
    createUser = try values.decodeIfPresent(Bool.self, forKey: "create_user") ?? true
    data = try values.decodeIfPresent([String: AnyJSON].self, forKey: "data")
    gotrueMetaSecurity = try values.decodeIfPresent(
      GoTrueMetaSecurity.self,
      forKey: "gotrue_meta_security"
    )
  }

  public func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: StringCodingKey.self)
    try values.encodeIfPresent(email, forKey: "email")
    try values.encodeIfPresent(phone, forKey: "phone")
    try values.encodeIfPresent(createUser, forKey: "create_user")
    try values.encodeIfPresent(data, forKey: "data")
    try values.encodeIfPresent(gotrueMetaSecurity, forKey: "gotrue_meta_security")
  }
}

public struct VerifyOTPParams: Codable, Equatable {
  public var email: String?
  public var phone: String?
  public var token: String
  public var type: OTPType
  public var gotrueMetaSecurity: GoTrueMetaSecurity?

  public init(
    email: String? = nil,
    phone: String? = nil,
    token: String,
    type: OTPType,
    gotrueMetaSecurity: GoTrueMetaSecurity? = nil
  ) {
    self.email = email
    self.phone = phone
    self.token = token
    self.type = type
    self.gotrueMetaSecurity = gotrueMetaSecurity
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: StringCodingKey.self)
    email = try values.decodeIfPresent(String.self, forKey: "email")
    phone = try values.decodeIfPresent(String.self, forKey: "phone")
    token = try values.decode(String.self, forKey: "token")
    type = try values.decode(OTPType.self, forKey: "type")
    gotrueMetaSecurity = try values.decodeIfPresent(
      GoTrueMetaSecurity.self,
      forKey: "gotrue_meta_security"
    )
  }

  public func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: StringCodingKey.self)
    try values.encodeIfPresent(email, forKey: "email")
    try values.encodeIfPresent(phone, forKey: "phone")
    try values.encode(token, forKey: "token")
    try values.encode(type, forKey: "type")
    try values.encodeIfPresent(gotrueMetaSecurity, forKey: "gotrue_meta_security")
  }
}

public enum OTPType: String, Codable, CaseIterable {
  case sms
  case phoneChange = "phone_change"
  case signup
  case invite
  case magiclink
  case recovery
  case emailChange = "email_change"
}

public enum AuthResponse: Codable, Equatable {
  case session(Session)
  case user(User)

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let value = try? container.decode(Session.self) {
      self = .session(value)
    } else if let value = try? container.decode(User.self) {
      self = .user(value)
    } else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Data could not be decoded as any of the expected types (Session, User)."
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case let .session(value): try container.encode(value)
    case let .user(value): try container.encode(value)
    }
  }
}

public struct UserAttributes: Codable, Equatable {
  /// The user's email.
  public var email: String?
  /// The user's phone.
  public var phone: String?
  /// The user's password.
  public var password: String?
  /// An email change token.
  public var emailChangeToken: String?
  /// A custom data object to store the user's metadata. This maps to the `auth.users.user_metadata`
  /// column. The `data` should be a JSON object that includes user-specific info, such as their
  /// first and last name.
  public var data: [String: AnyJSON]?

  public init(
    email: String? = nil,
    phone: String? = nil,
    password: String? = nil,
    emailChangeToken: String? = nil,
    data: [String: AnyJSON]? = nil
  ) {
    self.email = email
    self.phone = phone
    self.password = password
    self.emailChangeToken = emailChangeToken
    self.data = data
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: StringCodingKey.self)
    email = try values.decodeIfPresent(String.self, forKey: "email")
    phone = try values.decodeIfPresent(String.self, forKey: "phone")
    password = try values.decodeIfPresent(String.self, forKey: "password")
    emailChangeToken = try values.decodeIfPresent(String.self, forKey: "email_change_token")
    data = try values.decodeIfPresent([String: AnyJSON].self, forKey: "data")
  }

  public func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: StringCodingKey.self)
    try values.encodeIfPresent(email, forKey: "email")
    try values.encodeIfPresent(phone, forKey: "phone")
    try values.encodeIfPresent(password, forKey: "password")
    try values.encodeIfPresent(emailChangeToken, forKey: "email_change_token")
    try values.encodeIfPresent(data, forKey: "data")
  }
}

public struct RecoverParams: Codable, Equatable {
  public var email: String
  public var gotrueMetaSecurity: GoTrueMetaSecurity?

  public init(email: String, gotrueMetaSecurity: GoTrueMetaSecurity? = nil) {
    self.email = email
    self.gotrueMetaSecurity = gotrueMetaSecurity
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: StringCodingKey.self)
    email = try values.decode(String.self, forKey: "email")
    gotrueMetaSecurity = try values.decodeIfPresent(
      GoTrueMetaSecurity.self,
      forKey: "gotrue_meta_security"
    )
  }

  public func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: StringCodingKey.self)
    try values.encode(email, forKey: "email")
    try values.encodeIfPresent(gotrueMetaSecurity, forKey: "gotrue_meta_security")
  }
}
