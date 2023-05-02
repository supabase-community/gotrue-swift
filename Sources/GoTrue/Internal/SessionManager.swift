import Foundation
import KeychainAccess

struct StoredSession: Codable {
  var session: Session
  var expirationDate: Date

  func isValid(refreshToleranceInterval: TimeInterval) -> Bool {
    expirationDate > Date().addingTimeInterval(refreshToleranceInterval)
  }

  init(session: Session, expirationDate: Date? = nil) {
    self.session = session
    self.expirationDate = expirationDate ?? Date().addingTimeInterval(session.expiresIn)
  }
}

struct SessionManager {
  var session: () async throws -> Session
  var update: (_ session: Session) async throws -> Void
  var remove: () async -> Void
}

extension SessionManager {
  
  /// - Parameter refreshToleranceInterval: The amount of time added to "now", which determines when the current access token needs to be refreshed.
  /// A value of 60 would mean that a token which expires within 60 seconds of "now" would need to be refreshed.
  static func live(refreshToleranceInterval: TimeInterval) -> Self {
    let instance = LiveSessionManager()
    return Self(
      session: { try await instance.session(refreshToleranceInterval: refreshToleranceInterval) },
      update: { try await instance.update($0) },
      remove: { await instance.remove() }
    )
  }
}

private actor LiveSessionManager {
  private var task: Task<Session, Error>?
  
  func session(refreshToleranceInterval: TimeInterval) async throws -> Session {
    if let task {
      return try await task.value
    }

    guard let currentSession = try Env.localStorage.getSession() else {
      throw GoTrueError.sessionNotFound
    }

    if currentSession.isValid(refreshToleranceInterval: refreshToleranceInterval) {
      return currentSession.session
    }

    task = Task {
      defer { self.task = nil }

      let session = try await Env.sessionRefresher(currentSession.session.refreshToken)
      try update(session)
      return session
    }

    return try await task!.value
  }

  func update(_ session: Session) throws {
    try Env.localStorage.storeSession(StoredSession(session: session))
  }

  func remove() {
    Env.localStorage.deleteSession()
  }
}

extension GoTrueLocalStorage {
  fileprivate func getSession() throws -> StoredSession? {
    try retrieve(key: "supabase.session").flatMap {
      try JSONDecoder.goTrue.decode(StoredSession.self, from: $0)
    }
  }

  fileprivate func storeSession(_ session: StoredSession) throws {
    try store(key: "supabase.session", value: JSONEncoder.goTrue.encode(session))
  }

  fileprivate func deleteSession() {
    try? remove(key: "supabase.session")
  }
}
