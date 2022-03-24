import Foundation
import GoTrueHTTP

struct SessionNotFound: Error {}

actor SessionManager {
    private let keychain: KeychainClient
    private let sessionRefresher: (_ refreshToken: String) async throws -> Session
    private var task: Task<Session, Error>?

    init(
        serviceName: String? = nil,
        accessGroup: String? = nil,
        sessionRefresher: @escaping (_ refreshToken: String) async throws -> Session
    ) {
        keychain = KeychainClient(serviceName: serviceName, accessGroup: accessGroup)
        self.sessionRefresher = sessionRefresher
    }

    func session() async throws -> Session {
        if let task = task {
            return try await task.value
        }

        guard let currentSession = try keychain.getSession() else {
            throw SessionNotFound()
        }

        self.task = Task {
            defer { self.task = nil }

            let session = try await sessionRefresher(currentSession.refreshToken)
            try update(session)
            return session
        }

        return try await task!.value
    }

    func update(_ session: Session) throws {
        try keychain.storeSession(session)
    }

    func remove() {
        try keychain.deleteSession()
    }

    nonisolated var storedSession: Session? {
        try? keychain.getSession()
    }
}
