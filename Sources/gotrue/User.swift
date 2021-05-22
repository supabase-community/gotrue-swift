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

    init?(from dictionary: [String: Any]) {
        guard let id: String = dictionary["id"] as? String,
              let aud: String = dictionary["aud"] as? String,
              let email: String = dictionary["email"] as? String,
              let createdAt: String = dictionary["created_at"] as? String,
              let updatedAt: String = dictionary["updated_at"] as? String,
              let role: String = dictionary["role"] as? String
        else {
            return nil
        }

        self.id = id
        self.aud = aud
        self.email = email
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt

        if let confirmedAt: String = dictionary["confirmed_at"] as? String {
            self.confirmedAt = confirmedAt
        }

        if let lastSignInAt: String = dictionary["last_sign_in_at"] as? String {
            self.lastSignInAt = lastSignInAt
        }

        if let appMetadata: [String: Any] = dictionary["app_metadata"] as? [String: Any] {
            self.appMetadata = appMetadata
        }

        if let userMetadata: [String: Any] = dictionary["user_metadata"] as? [String: Any] {
            self.userMetadata = userMetadata
        }
    }
}
