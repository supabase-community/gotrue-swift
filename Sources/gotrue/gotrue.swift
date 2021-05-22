
import Foundation

enum Provider: String {
    case azure
    case bitbucket
    case facebook
    case github
    case gitlab
    case google
}

public enum AuthChangeEvent: String {
    case SIGNED_IN
    case SIGNED_OUT
    case USER_UPDATED
    case USER_DELETED
    case PASSWORD_RECOVERY
}

public struct CookieOptions {
    var name: String
    var lifetime: Int
    var domain: String
    var path: String
    var sameSite: String

    init(name: String = Constants.Cookie.name, lifetime: Int = Constants.Cookie.lifetime, domain: String = Constants.Cookie.domain, path: String = Constants.Cookie.path, sameSite: String = Constants.Cookie.sameSite) {
        self.name = name
        self.lifetime = lifetime
        self.domain = domain
        self.path = path
        self.sameSite = sameSite
    }
}

public enum Constants {
    public static var defaultGotrueUrl = "http://localhost:9999"
    public static var defaultAudience = ""
    public static var defaultHeaders: [String: String] = [:]
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

struct GoTrueError: Error {
    var statusCode: Int?
    var message: String?
}

extension GoTrueError: LocalizedError {
    var errorDescription: String? {
        return message
    }
}

class GoTrueApi {
    var url: String
    var headers: [String: String]
    var cookieOptions: CookieOptions?

    init(url: String, headers: [String: String], cookieOptions: CookieOptions?) {
        self.url = url
        self.headers = headers
        self.cookieOptions = cookieOptions
    }

    /// HTTP Methods
    private enum HTTPMethod: String {
        case get = "GET"
        case head = "HEAD"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case connect = "CONNECT"
        case options = "OPTIONS"
        case trace = "TRACE"
        case patch = "PATCH"
    }

    func signUpWithEmail(email: String, password: String, completion: @escaping (Result<Session?, Error>) -> Void) {
        guard let url = URL(string: "\(url)/signup") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }

        fetch(url: url, method: .post, parameters: ["email": email, "password": password]) { result in
            switch result {
            case let .success(response):
                guard let dict: [String: Any] = response as? [String: Any], let session = Session(from: dict) else {
                    completion(.failure(GoTrueError(message: "failed to parse response")))
                    return
                }
                completion(.success(session))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func signInWithEmail(email: String, password: String, completion: @escaping (Result<Session?, Error>) -> Void) {
        guard let url = URL(string: "\(url)/token?grant_type=password") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }

        fetch(url: url, method: .post, parameters: ["email": email, "password": password]) { result in
            switch result {
            case let .success(response):
                guard let dict: [String: Any] = response as? [String: Any], let session = Session(from: dict) else {
                    completion(.failure(GoTrueError(message: "failed to parse response")))
                    return
                }
                completion(.success(session))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func refreshAccessToken(refreshToken: String, completion: @escaping (Result<Session?, Error>) -> Void) {
        guard let url = URL(string: "\(url)/token?grant_type=refresh_token") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }

        fetch(url: url, method: .post, parameters: ["refresh_token": refreshToken]) { result in
            switch result {
            case let .success(response):
                guard let dict: [String: Any] = response as? [String: Any], let session = Session(from: dict) else {
                    completion(.failure(GoTrueError(message: "failed to parse response")))
                    return
                }
                completion(.success(session))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func fetch(url: URL, method: HTTPMethod = .get, parameters: [String: Any]?, completion: @escaping (Result<Any, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        if let parameters = parameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
            } catch {
                completion(.failure(error))
                return
            }
        }

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request, completionHandler: { [unowned self] (data, response, error) -> Void in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let resp = response as? HTTPURLResponse {
                if let data = data {
                    do {
                        completion(.success(try self.parse(response: try JSONSerialization.jsonObject(with: data, options: []), statusCode: resp.statusCode)))
                    } catch {
                        completion(.failure(error))
                        return
                    }
                }
            } else {}

        })

        dataTask.resume()
    }

    private func parse(response: Any, statusCode: Int) throws -> Any {
        if statusCode == 200 || 200 ..< 300 ~= statusCode {
            return response
        } else if let dict = response as? [String: Any], let message = dict["msg"] as? String {
            throw GoTrueError(statusCode: statusCode, message: message)
        } else if let dict = response as? [String: Any], let message = dict["error_description"] as? String {
            throw GoTrueError(statusCode: statusCode, message: message)
        } else {
            return response
        }
    }
}

public class GoTrueClient {
    var api: GoTrueApi
    var currentUser: User?
    var currentSession: Session?
    var autoRefreshToken: Bool

    var refreshTokenTimer: Timer?

    public typealias StateChangeEvent = (AuthChangeEvent) -> Void
    public var onAuthStateChange: StateChangeEvent?

    public init(url: String = Constants.defaultGotrueUrl, headers: [String: String] = Constants.defaultHeaders, autoRefreshToken: Bool = true, cookieOptions: CookieOptions? = nil) {
        api = GoTrueApi(url: url, headers: headers, cookieOptions: cookieOptions)
        self.autoRefreshToken = autoRefreshToken
    }

    public func signUp(email: String, password: String, completion: @escaping (Result<Session, Error>) -> Void) {
        removeSession()

        api.signUpWithEmail(email: email, password: password) { [unowned self] result in
            switch result {
            case let .success(session):
                if let session = session {
                    self.saveSession(session: session)
                    self.onAuthStateChange?(.SIGNED_IN)
                    completion(.success(session))
                } else {
                    completion(.failure(GoTrueError(message: "failed to get session")))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func saveSession(session: Session) {
        currentSession = session
        currentUser = session.user

        if let tokenExpirySeconds = session.expiresIn, autoRefreshToken {
            if refreshTokenTimer != nil {
                refreshTokenTimer?.invalidate()
                refreshTokenTimer = nil
            }

            refreshTokenTimer = Timer(fire: Date().addingTimeInterval(TimeInterval(tokenExpirySeconds)), interval: 0, repeats: false, block: { [unowned self] _ in
                callRefreshToken(refreshToken: self.currentSession?.refreshToken) { [unowned self] result in
                    switch result {
                    case let .success(session):
                        self.saveSession(session: session)
                        self.onAuthStateChange?(.SIGNED_IN)
                    case let .failure(error):
                        print(error.localizedDescription)
                    }
                }
            })
        }
    }

    func removeSession() {
        currentUser = nil
        currentSession = nil
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
}

public struct Session {
    public var accessToken: String
    public var tokenType: String?
    var expiresIn: Int?
    var refreshToken: String?
    public var user: User?

    init?(from dictionary: [String: Any]) {
        guard let accessToken: String = dictionary["access_token"] as? String else {
            return nil
        }

        self.accessToken = accessToken

        if let tokenType: String = dictionary["token_type"] as? String {
            self.tokenType = tokenType
        }

        if let expiresIn: Int = dictionary["expires_in"] as? Int {
            self.expiresIn = expiresIn
        }

        if let refreshToken: String = dictionary["refresh_token"] as? String {
            self.refreshToken = refreshToken
        }

        if let user: [String: Any] = dictionary["user"] as? [String: Any] {
            self.user = User(from: user)
        }
    }
}

public struct User {
    public var id: String
    public var aud: String
    public var role: String
    public var email: String
    public var confirmedAt: String?
    public var lastSignInAt: String?
    public var appMetadata: [String: Any]?
    public var userMetadata: [String: Any]?
    public var createdAt: String
    public var updatedAt: String

    init?(from dictionary: [String: Any]) {
        guard let id: String = dictionary["id"] as? String,
              let aud: String = dictionary["aud"] as? String,
              let email: String = dictionary["email"] as? String,
              let createdAt: String = dictionary["created_at"] as? String,
              let updatedAt: String = dictionary["updated_at"] as? String,
              let role: String = dictionary["role"] as? String
        else {
            return nil
        }

        self.id = id
        self.aud = aud
        self.email = email
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt

        if let confirmedAt: String = dictionary["confirmed_at"] as? String {
            self.confirmedAt = confirmedAt
        }

        if let lastSignInAt: String = dictionary["last_sign_in_at"] as? String {
            self.lastSignInAt = lastSignInAt
        }

        if let appMetadata: [String: Any] = dictionary["app_metadata"] as? [String: Any] {
            self.appMetadata = appMetadata
        }

        if let userMetadata: [String: Any] = dictionary["user_metadata"] as? [String: Any] {
            self.userMetadata = userMetadata
        }
    }
}
