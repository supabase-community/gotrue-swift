public struct Session {
    public var accessToken: String
    public var tokenType: String?
    var expiresIn: Int?
    var refreshToken: String?
    public var user: User?

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
