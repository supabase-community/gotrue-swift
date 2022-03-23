import Foundation
import Get
import GoTrueHTTP
import Combine

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class GoTrueClient {
    private let client: APIClient
    private let authEventChangeSubject: CurrentValueSubject<AuthChangeEvent, Never>
    private let sessionManager: SessionManager

    public lazy var authEventChange = authEventChangeSubject.share().eraseToAnyPublisher()

    public var session: Session? {
        sessionManager.getSession()
    }

    /// Initializes the GoTrue Client with the provided parameters.
    /// - Parameters:
    ///   - host: Host of the GoTrue server.
    ///   - headers: Any headers to include with network requests.
    ///   - keychainAccessGroup: A shared keychain access group to use (Optional).
    public init(
        url: URL,
        headers: [String: String] = [:],
        keychainAccessGroup: String? = nil
    ) {
        guard let host = URLComponents(url: url, resolvingAgainstBaseURL: false)?.host else {
            preconditionFailure("Invalid URL provided: \(url)")
        }

        self.client = APIClient(host: host) {
            $0.sessionConfiguration.httpAdditionalHeaders = headers
        }
        self.sessionManager = SessionManager(accessGroup: keychainAccessGroup)
        self.authEventChangeSubject = CurrentValueSubject<AuthChangeEvent, Never>(sessionManager.getSession() != nil ? .signedIn : .signedOut)
    }

    public func signUp(email: String, password: String) async throws -> Paths.Signup.PostResponse {
        sessionManager.removeSession()
        return try await client.send(Paths.signup.post(.init(email: email, password: password))).value
    }

    public func signIn(email: String, password: String) async throws -> Session {
        sessionManager.removeSession()

        do {
            let session = try await client.send(
                Paths.token.post(grantType: .password, TokenRequest(email: email, password: password))
            ).value
            sessionManager.saveSession(session)
            authEventChangeSubject.send(.signedIn)
            return session
        } catch {
            throw error
        }
    }
}
