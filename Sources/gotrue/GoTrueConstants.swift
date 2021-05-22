public enum GoTrueConstants {
    public static var defaultGotrueUrl = "http://localhost:9999"
    public static var defaultAudience = ""
    public static var defaultHeaders: [String: String] = ["Content-Type": "application/json"]
    public static var defaultExpiryMargin = 60 * 1000
    public static var defaultStorageKey = "supabase.auth.token"

    enum Cookie {
        static var name = "sb:token"
        static var lifetime: Int = 60 * 60 * 8
        static var domain: String = ""
        static var path: String = ""
        static var sameSite: String = "lax"
    }
}
