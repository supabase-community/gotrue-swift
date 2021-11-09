import Foundation

public typealias AuthStateChangeCallback = (_ event: AuthChangeEvent, _ session: Session?) -> Void

public struct Subscription {
    let callback: AuthStateChangeCallback

    public let unsubscribe: () -> Void
}

public class GoTrueClient {
    var api: GoTrueApi
    var currentSession: Session?
    var autoRefreshToken: Bool
    var refreshTokenTimer: Timer?

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

    public var user: User? {
        return currentSession?.user
    }

    public var session: Session? {
        return currentSession
    }

    public init(url: String = GoTrueConstants.defaultGotrueUrl, headers: [String: String] = [:], autoRefreshToken: Bool = true) {
        api = GoTrueApi(url: url, headers: headers)
        self.autoRefreshToken = autoRefreshToken

        // recover session from storage
        if let session = UserDefaults.standard.value(Session.self, forKey: "\(GoTrueConstants.defaultStorageKey).session") {
            currentSession = session
        }
    }

    public func signUp(email: String, password: String, completion: @escaping (Result<(session: Session?, user: User?), Error>) -> Void) {
        removeSession()

        api.signUpWithEmail(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(data):
                if let session = data.session {
                    self.saveSession(session: session)
                    self.notifyAllStateChangeListeners(.signedIn)
                }
                completion(.success(data))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func signIn(email: String, password: String, completion: @escaping (Result<Session, Error>) -> Void) {
        removeSession()

        api.signInWithEmail(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(session):
                self.saveSession(session: session)
                self.notifyAllStateChangeListeners(.signedIn)
                completion(.success(session))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func signIn(email: String, completion: @escaping (Result<Any?, Error>) -> Void) {
        removeSession()

        api.sendMagicLinkEmail(email: email) { result in
            switch result {
            case let .success(data):
                completion(.success(data))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func signIn(provider: Provider, options: ProviderOptions? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        removeSession()

        do {
            let providerURL = try api.getUrlForProvider(provider: provider, options: options)
            completion(.success(providerURL))
        } catch {
            completion(.failure(error))
        }
    }

    public func update(emailChangeToken: String? = nil, password: String? = nil, data: [String: Any]? = nil, completion: @escaping (Result<User, Error>) -> Void) {
        guard let accessToken = currentSession?.accessToken else {
            completion(.failure(GoTrueError(message: "current session not found")))
            return
        }

        api.updateUser(accessToken: accessToken, emailChangeToken: emailChangeToken, password: password, data: data) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(user):
                self.notifyAllStateChangeListeners(.userUpdated)
                self.currentSession?.user = user
                if let currentSession = self.currentSession {
                    self.saveSessionToStorage(currentSession)
                }
                completion(.success(user))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getSessionFromUrl(url: String, completion: @escaping (Result<Session, Error>) -> Void) {
        let components = URLComponents(string: url)

        guard let queryItems = components?.queryItems,
              let accessToken: String = queryItems.first(where: { item in item.name == "access_token" })?.value,
              let expiresIn: String = queryItems.first(where: { item in item.name == "expires_in" })?.value,
              let refreshToken: String = queryItems.first(where: { item in item.name == "refresh_token" })?.value,
              let tokenType: String = queryItems.first(where: { item in item.name == "token_type" })?.value
        else {
            completion(.failure(GoTrueError(message: "bad credentials")))
            return
        }

        let providerToken = queryItems.first(where: { item in item.name == "provider_token" })?.value

        api.getUser(accessToken: accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(user):
                let session = Session(accessToken: accessToken, tokenType: tokenType, user: user, expiresIn: Int(expiresIn), refreshToken: refreshToken, providerToken: providerToken)
                self.saveSession(session: session)
                self.notifyAllStateChangeListeners(.signedIn)

                if let type: String = queryItems.first(where: { item in item.name == "type" })?.value, type == "recovery" {
                    self.notifyAllStateChangeListeners(.passwordRecovery)
                }

                completion(.success(session))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func saveSessionToStorage(_ session: Session) {
        UserDefaults.standard.set(encodable: session, forKey: "\(GoTrueConstants.defaultStorageKey).session")
    }

    private func saveSession(session: Session) {
        currentSession = session

        saveSessionToStorage(session)

        if let tokenExpirySeconds = session.expiresIn, autoRefreshToken {
            if refreshTokenTimer != nil {
                refreshTokenTimer?.invalidate()
                refreshTokenTimer = nil
            }

            refreshTokenTimer = Timer(fireAt: Date().addingTimeInterval(TimeInterval(tokenExpirySeconds)), interval: 0, target: self, selector: #selector(refreshToken), userInfo: nil, repeats: false)
        }
    }

    @objc
    private func refreshToken() {
        callRefreshToken(refreshToken: currentSession?.refreshToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(session):
                self.saveSession(session: session)
                self.notifyAllStateChangeListeners(.signedIn)
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }

    private func removeSession() {
        currentSession = nil

        UserDefaults.standard.removeObject(forKey: "\(GoTrueConstants.defaultStorageKey).session")
    }

    public func refreshSession(completion: @escaping (Result<Session, Error>) -> Void) {
        guard let refreshToken = currentSession?.refreshToken else {
            completion(.failure(GoTrueError(message: "Not logged in.")))
            return
        }
        callRefreshToken(refreshToken: refreshToken) { result in
            completion(result)
        }
    }

    public func signOut(completion: @escaping (Result<Data, Error>) -> Void) {
        guard let accessToken = currentSession?.accessToken else {
            completion(.failure(GoTrueError(message: "current session not found")))
            return
        }

        removeSession()
        notifyAllStateChangeListeners(.signedOut)
        api.signOut(accessToken: accessToken) { result in
            completion(result)
        }
    }

    private func callRefreshToken(refreshToken: String?, completion: @escaping (Result<Session, Error>) -> Void) {
        guard let refreshToken = refreshToken else {
            completion(.failure(GoTrueError(message: "current session not found")))
            return
        }

        api.refreshAccessToken(refreshToken: refreshToken, completion: completion)
    }

    private func notifyAllStateChangeListeners(_ event: AuthChangeEvent) {
        stateChangeListeners.values.forEach {
            $0.callback(event, session)
        }
    }
}

#if compiler(>=5.5)
    @available(iOS 15.0.0, macOS 12.0.0, *)
    public extension GoTrueClient {
        func onAuthStateChange() -> AsyncStream<(AuthChangeEvent, Session?)> {
            AsyncStream { continuation in
                _ = onAuthStateChange { event, session in
                    continuation.yield((event, session))
                }

                // How to stop subscription?
                // continuation.onTermination = { subscription.unsubscribe() }
            }
        }

        func signUp(email: String, password: String) async throws -> (session: Session?, user: User?) {
            try await withCheckedThrowingContinuation { continuation in
                signUp(email: email, password: password) { result in
                    continuation.resume(with: result)
                }
            }
        }

        func signIn(email: String, password: String) async throws -> Session {
            try await withCheckedThrowingContinuation { continuation in
                signIn(email: email, password: password) { result in
                    continuation.resume(with: result)
                }
            }
        }

        func signIn(email: String) async throws -> Any? {
            try await withCheckedThrowingContinuation { continuation in
                signIn(email: email) { result in
                    continuation.resume(with: result)
                }
            }
        }

        func update(emailChangeToken: String? = nil, password: String? = nil, data: [String: Any]? = nil) async throws -> User {
            try await withCheckedThrowingContinuation { continuation in
                update(emailChangeToken: emailChangeToken, password: password, data: data) { result in
                    continuation.resume(with: result)
                }
            }
        }

        func getSessionFromUrl(url: String) async throws -> Session {
            try await withCheckedThrowingContinuation { continuation in
                getSessionFromUrl(url: url) { result in
                    continuation.resume(with: result)
                }
            }
        }

        func refreshSession() async throws -> Session {
            try await withCheckedThrowingContinuation { continuation in
                refreshSession { result in
                    continuation.resume(with: result)
                }
            }
        }

        func signOut() async throws -> Any? {
            try await withCheckedThrowingContinuation { continuation in
                signOut { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
#endif
