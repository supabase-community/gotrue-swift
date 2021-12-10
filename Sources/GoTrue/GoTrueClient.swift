import Foundation
import SimpleHTTP

public typealias AuthStateChangeCallback = (_ event: AuthChangeEvent, _ session: Session?) -> Void

public struct Subscription {
    let callback: AuthStateChangeCallback

    public let unsubscribe: () -> Void
}

public class GoTrueClient {
    private var stateChangeListeners: [String: Subscription] = [:]

    /// Receive a notification every time an auth event happens.
    /// - Returns: A subscription object which can be used to unsubscribe itself.
    public func onAuthStateChange(_ callback: @escaping (_ event: AuthChangeEvent, _ session: Session?) -> Void) -> Subscription {
        let id = UUID().uuidString

        let subscription = Subscription(
            callback: callback,
            unsubscribe: { [weak self] in
                self?.stateChangeListeners[id] = nil
            }
        )

        stateChangeListeners[id] = subscription
        return subscription
    }

    public var session: Session {
        get async throws { try await Env.sessionManager.session() }
    }

    public init(
        url: String,
        apiKey: String,
        keychainAccessGroup: String? = nil
    ) {
        let url = URL(string: url)!
        Env = Environment(
            url: { url },
            httpClient: HTTPClient(
                baseURL: url,
                adapters: [DefaultHeaders(), APIKeyRequestAdapter(apiKey: apiKey)],
                interceptors: [StatusCodeValidator()]
            ),
            api: GoTrueApi(),
            sessionStorage: .keychain(accessGroup: keychainAccessGroup),
            sessionManager: .live
        )
    }

    public func signUp(email: String, password: String) async throws -> User {
        try await Env.api.signUpWithEmail(email: email, password: password)
    }

    public func signIn(email: String, password: String) async throws -> Session {
        await Env.sessionManager.removeSession()

        let session = try await Env.api.signInWithEmail(email: email, password: password)
        await Env.sessionManager.updateSession(session)
        await notifyAllStateChangeListeners(.signedIn)
        return session
    }

    public func signIn(email: String) async throws {
        await Env.sessionManager.removeSession()
        try await Env.api.sendMagicLinkEmail(email: email)
    }

    public func signIn(provider: Provider, options: ProviderOptions? = nil) async throws -> URL {
        await Env.sessionManager.removeSession()
        let providerURL = try Env.api.getUrlForProvider(provider: provider, options: options)
        return providerURL
    }

    public func update(user: UpdateUserParams) async throws -> User {
        let user = try await Env.api.updateUser(params: user)

        await notifyAllStateChangeListeners(.userUpdated)
        await Env.sessionManager.updateUser(user)
        return user
    }

    public func getSessionFromUrl(url: String) async throws -> Session {
        let components = URLComponents(string: url)

        guard
            let queryItems = components?.queryItems,
            let accessToken = queryItems["access_token"],
            let expiresIn = queryItems["expires_in"],
            let refreshToken = queryItems["refresh_token"],
            let tokenType = queryItems["token_type"]
        else {
            throw GoTrueError.badCredentials
        }

        let providerToken = queryItems["provider_token"]

        let user = try await Env.api.getUser()
        let session = Session(
            accessToken: accessToken, tokenType: tokenType, expiresIn: Int(expiresIn) ?? 0,
            refreshToken: refreshToken, providerToken: providerToken, user: user
        )
        await Env.sessionManager.updateSession(session)
        await notifyAllStateChangeListeners(.signedIn)

        if let type = queryItems["type"], type == "recovery" {
            await notifyAllStateChangeListeners(.passwordRecovery)
        }

        return session
    }

    public func signOut() async throws {
        await Env.sessionManager.removeSession()
        await notifyAllStateChangeListeners(.signedOut)
        try await Env.api.signOut()
    }

    private func callRefreshToken(refreshToken: String?) async throws -> Session {
        guard let refreshToken = refreshToken else {
            throw GoTrueError(message: "current session not found")
        }

        return try await Env.api.refreshAccessToken(refreshToken: refreshToken)
    }

    private func notifyAllStateChangeListeners(_ event: AuthChangeEvent) async {
        let session = try? await session
        stateChangeListeners.values.forEach {
            $0.callback(event, session)
        }
    }
}
