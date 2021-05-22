public struct CookieOptions {
    var name: String
    var lifetime: Int
    var domain: String
    var path: String
    var sameSite: String

    init(name: String = GoTrueConstants.Cookie.name, lifetime: Int = GoTrueConstants.Cookie.lifetime, domain: String = GoTrueConstants.Cookie.domain, path: String = GoTrueConstants.Cookie.path, sameSite: String = GoTrueConstants.Cookie.sameSite) {
        self.name = name
        self.lifetime = lifetime
        self.domain = domain
        self.path = path
        self.sameSite = sameSite
    }
}
