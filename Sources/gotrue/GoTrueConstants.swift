public enum GoTrueConstants {
    public static var defaultGotrueUrl = "http://localhost:9999"
    public static var defaultAudience = ""
    public static var defaultHeaders: [String: String] = ["Content-Type": "application/json"]
    public static var defaultExpiryMargin = 60 * 1000
    public static var defaultStorageKey = "supabase.auth.token"

    public enum Cookie {
        public static var name = "sb:token"
        public static var lifetime: Int = 60 * 60 * 8
        public static var domain: String = ""
        public static var path: String = ""
        public static var sameSite: String = "lax"
    }
}
