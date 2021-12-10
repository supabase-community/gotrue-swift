import AnyCodable
import Foundation
import SimpleHTTP

struct APIKeyRequestAdapter: RequestAdapter {
    let apiKey: String

    func adapt(_ client: HTTPClient, _ request: URLRequest) async throws -> URLRequest {
    var request = request
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        return request
    }
}

struct Authenticator: RequestAdapter {
    func adapt(_ client: HTTPClient, _ request: URLRequest) async throws -> URLRequest {
        var request = request
        let session = try await Env.sessionManager.session()
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}

struct APIErrorInterceptor: ResponseInterceptor {
    func intercept(_ client: HTTPClient, _ result: Result<Response, Error>) async throws -> Response {
        do {
            return try result.get()
        } catch let error as APIError {
            let response = try error.response.decoded(to: ErrorResponse.self)
            throw GoTrueError(
                statusCode: error.response.statusCode,
                message: response.msg ?? response.message ?? "Error: status_code=\(error.response.statusCode)"
            )
        } catch {
            throw error
        }
    }

    private struct ErrorResponse: Decodable {
        let msg: String?
        let message: String?
    }
}

class GoTrueApi {
    func signUpWithEmail(email: String, password: String) async throws -> User {
        try await Env.httpClient.request(
            Endpoint(path: "signup", method: .post, body: try JSONEncoder().encode(["email": email, "password": password]))
        ).decoded(to: User.self)
    }

    func signInWithEmail(email: String, password: String) async throws -> Session {
        try await Env.httpClient.request(
            Endpoint(
                path: "/token", method: .post, query: [URLQueryItem(name: "grant_type", value: "password")],
                body: try JSONEncoder().encode(["email": email, "password": password])
            )
        ).decoded(to: Session.self)
    }

    func sendMagicLinkEmail(email: String) async throws {
        _ = try await Env.httpClient.request(Endpoint(path: "magiclink", method: .post, body: try JSONEncoder().encode(["email": email])))
    }

    func getUrlForProvider(provider: Provider, options: ProviderOptions?) throws -> URL {
        guard var components = URLComponents(url: Env.url().appendingPathComponent("authorize"), resolvingAgainstBaseURL: false) else {
            throw GoTrueError.badURL
        }

        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "provider", value: provider.rawValue))
        if let options = options {
            if let scopes = options.scopes {
                queryItems.append(URLQueryItem(name: "scopes", value: scopes))
            }
            if let redirectTo = options.redirectTo {
                queryItems.append(URLQueryItem(name: "redirect_to", value: redirectTo))
            }
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw GoTrueError.badURL
        }

        return url
    }

    func refreshAccessToken(refreshToken: String) async throws -> Session {
        try await Env.httpClient.request(
            Endpoint(
                path: "/token", method: .post, query: [URLQueryItem(name: "grant_type", value: "refresh_token")],
                body: try JSONEncoder().encode(["refresh_token": refreshToken])
            )
        )
        .decoded(to: Session.self)
    }

    func signOut() async throws {
        _ = try await Env.httpClient.request(Endpoint(path: "/logout", method: .post))
    }

    func updateUser(params: UpdateUserParams) async throws -> User {
        try await Env.httpClient.request(
            Endpoint(path: "/user", method: .put, body: try JSONEncoder().encode(params))
        ).decoded(to: User.self)
    }

    func getUser() async throws -> User {
        try await Env.httpClient.request(Endpoint(path: "/user", method: .get)).decoded(to: User.self)
    }
}
