public enum Provider: String {
    case azure
    case bitbucket
    case facebook
    case github
    case gitlab
    case google
}

public struct ProviderOptions {
    public var redirectTo: String?
    public var scopes: String?

    public init(redirectTo: String?, scopes: String?) {
        self.redirectTo = redirectTo
        self.scopes = scopes
    }
}
