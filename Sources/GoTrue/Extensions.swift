import Get
import Foundation

extension AuthResponse {
    public var user: User? {
        if case let .user(user) = self { return user }
        return nil
    }
    
    public var session: Session? {
        if case let .session(session) = self { return session }
        return nil
    }
}

extension Request {
    func withAuthorization(_ token: String, type: String = "Bearer") -> Self {
        var copy = self
        var headers = copy.headers ?? [:]
        headers["Authorization"] = "\(type) \(token)"
        copy.headers = headers
        return copy
    }
}

extension URL {
    public var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}

extension Data {
    // Returns a base64 encoded string, replacing reserved characters
    // as per the PKCE spec https://tools.ietf.org/html/rfc7636#section-4.2
    func pkceBase64EncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}
