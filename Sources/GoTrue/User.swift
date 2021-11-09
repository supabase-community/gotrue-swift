import AnyCodable
public struct User {
    public var id: String
    public var aud: String
    public var role: String
    public var email: String
    public var confirmedAt: String?
    public var lastSignInAt: String?
    public var appMetadata: [String: Any]?
    public var userMetadata: [String: Any]?
    public var createdAt: String
    public var updatedAt: String
}

extension User: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case aud
        case role
        case email
        case confirmedAt = "confirmed_at"
        case lastSignInAt = "last_sign_in_at"
        case appMetadata = "app_metadata"
        case userMetadata = "user_metadata"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        aud = try container.decode(String.self, forKey: .aud)
        role = try container.decode(String.self, forKey: .role)
        email = try container.decode(String.self, forKey: .email)
        confirmedAt = try container.decode(String.self, forKey: .confirmedAt)
        lastSignInAt = try container.decode(String.self, forKey: .lastSignInAt)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        appMetadata = try container.decodeIfPresent([String: AnyDecodable].self, forKey: .appMetadata)?.mapValues(\.value)
        userMetadata = try container.decodeIfPresent([String: AnyDecodable].self, forKey: .userMetadata)?.mapValues(\.value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(aud, forKey: .aud)
        try container.encode(role, forKey: .role)
        try container.encode(email, forKey: .email)
        try container.encode(confirmedAt, forKey: .confirmedAt)
        try container.encode(lastSignInAt, forKey: .lastSignInAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(appMetadata?.mapValues(AnyEncodable.init), forKey: .appMetadata)
        try container.encodeIfPresent(userMetadata?.mapValues(AnyEncodable.init), forKey: .userMetadata)
    }
}
