public struct Session {
    public var accessToken: String
    public var tokenType: String?
    public var user: User?

    var expiresIn: Int?
    var refreshToken: String?

    init?(from dictionary: [String: Any]) {
        guard let accessToken: String = dictionary["access_token"] as? String else {
            return nil
        }

        self.accessToken = accessToken

        if let tokenType: String = dictionary["token_type"] as? String {
            self.tokenType = tokenType
        }

        if let expiresIn: Int = dictionary["expires_in"] as? Int {
            self.expiresIn = expiresIn
        }

        if let refreshToken: String = dictionary["refresh_token"] as? String {
            self.refreshToken = refreshToken
        }

        if let user: [String: Any] = dictionary["user"] as? [String: Any] {
            self.user = User(from: user)
        }
    }
}

extension Session: Codable {
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        tokenType = try? container.decode(String.self, forKey: .tokenType)
        expiresIn = try? container.decode(Int.self, forKey: .expiresIn)
        refreshToken = try? container.decode(String.self, forKey: .refreshToken)
        user = try? container.decode(User.self, forKey: .user)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(tokenType, forKey: .tokenType)
        try container.encode(expiresIn, forKey: .expiresIn)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(user, forKey: .user)
    }
}
