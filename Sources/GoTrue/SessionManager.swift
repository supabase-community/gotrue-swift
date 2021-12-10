import Foundation
import XCTestDynamicOverlay

struct SessionManager {
    var session: () async throws -> Session
    var removeSession: () async -> Void
    var updateSession: (Session) async -> Void
    var updateUser: (User) async -> Void
}

extension SessionManager {
    static let live: SessionManager = {
        let manager = _SessionManager()
        return SessionManager(
            session: manager.session,
            removeSession: { await manager.removeSession() },
            updateSession: { await manager.update(session: $0) },
            updateUser: { await manager.update(user: $0) }
        )
    }()

#if DEBUG
    static var failing: SessionManager {
        SessionManager(
            session: {
                XCTFail("SessionManager.session() called but was not implemented.")
                return .dummy
            },
            removeSession: {
                XCTFail("SessionManager.removeSession() called but was not implemented.")
            },
            updateSession: { _ in
                XCTFail("SessionManager.updateSession(_:) called but was not implemented.")
            },
            updateUser: { _ in
                XCTFail("SessionManager.updateUser(_:) called but was not implemented.")
            }
        )
    }

    static var noop: SessionManager {
        SessionManager(
            session: { .dummy },
            removeSession: {},
            updateSession: { _ in },
            updateUser: { _ in }
        )
    }
#endif

}

private actor _SessionManager {
    private var refreshTask: Task<Session, Error>?

    private var currentSession: Session? {
        get { try? Env.sessionStorage.get() }
        set {
            if let newValue = newValue {
                try? Env.sessionStorage.store(newValue)
            } else {
                try? Env.sessionStorage.delete()
            }
        }
    }

    func session() async throws -> Session {
        if let refreshTask = refreshTask {
            return try await refreshTask.value
        }

        guard let currentSession = currentSession else {
            throw GoTrueError(statusCode: nil, message: "Session not found.")
        }

        // TODO: check if session is valid
        // if currentSession.isValid {
        //  return currentSession
        // }
        let task = Task { () async throws -> Session in
            defer { refreshTask = nil }

            let newSession = try await Env.api.refreshAccessToken(refreshToken: currentSession.refreshToken)
            self.update(session: newSession)
            return newSession
        }

        refreshTask = task
        return try await task.value
    }

    func removeSession() {
        currentSession = nil
    }

    func update(session: Session) {
        currentSession = session
    }

    func update(user: User) {
        currentSession?.user = user
    }
}
