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

        api.signUpWithEmail(email: email, password: password) { [unowned self] result in
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

        api.signInWithEmail(email: email, password: password) { [unowned self] result in
            switch result {
            case let .success(session):
                if let session = session {
                    self.saveSession(session: session)
                    self.notifyAllStateChangeListeners(.signedIn)
                    completion(.success(session))
                } else {
                    completion(.failure(GoTrueError(message: "failed to get session")))
                }
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

        api.updateUser(accessToken: accessToken, emailChangeToken: emailChangeToken, password: password, data: data) { [unowned self] result in
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

        api.getUser(accessToken: accessToken) { [unowned self] result in
            switch result {
            case let .success(user):
                let session = Session(accessToken: accessToken, tokenType: tokenType, expiresIn: Int(expiresIn), refreshToken: refreshToken, providerToken: providerToken, user: user)
                saveSession(session: session)
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

    fileprivate func saveSessionToStorage(_ session: Session) {
        // save session to storage
        UserDefaults.standard.set(encodable: session, forKey: "\(GoTrueConstants.defaultStorageKey).session")
    }

    func saveSession(session: Session) {
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
    func refreshToken() {
        callRefreshToken(refreshToken: currentSession?.refreshToken) { [unowned self] result in
            switch result {
            case let .success(session):
                self.saveSession(session: session)
                self.notifyAllStateChangeListeners(.signedIn)
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }

    func removeSession() {
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

    public func signOut(completion: @escaping (Result<Any?, Error>) -> Void) {
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

    func callRefreshToken(refreshToken: String?, completion: @escaping (Result<Session, Error>) -> Void) {
        guard let refreshToken = refreshToken else {
            completion(.failure(GoTrueError(message: "current session not found")))
            return
        }

        api.refreshAccessToken(refreshToken: refreshToken) { result in
            switch result {
            case let .success(session):
                if let session = session {
                    completion(.success(session))
                } else {
                    completion(.failure(GoTrueError(message: "failed to get session")))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func notifyAllStateChangeListeners(_ event: AuthChangeEvent) {
        stateChangeListeners.values.forEach {
            $0.callback(event, session)
        }
    }
}
