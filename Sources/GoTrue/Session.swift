public struct Session: Codable {
    public let accessToken: String
    public let tokenType: String
    public let expiresIn: Int
    public let refreshToken: String
    public let providerToken: String?
    public internal(set) var user: User
}

#if DEBUG

extension Session {
    static let dummy = Session(accessToken: "", tokenType: "", expiresIn: 0, refreshToken: "", providerToken: nil, user: .dummy)
}
#endif
