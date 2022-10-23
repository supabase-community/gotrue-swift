import Foundation
import KeychainAccess

struct StoredSession: Codable {
  var session: Session
  var expirationDate: Date

  var isValid: Bool {
    expirationDate > Date().addingTimeInterval(-60)
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
  static var live: Self {
    let instance = LiveSessionManager()
    return Self(
      session: { try await instance.session() },
      update: { try await instance.update($0) },
      remove: { await instance.remove() }
    )
  }
}

private actor LiveSessionManager {
  private var task: Task<Session, Error>?

  func session() async throws -> Session {
    if let task = task {
      return try await task.value
    }

    guard let currentSession = try await Current.localStorage.getSession() else {
      throw GoTrueError.sessionNotFound
    }

    if currentSession.isValid {
      return currentSession.session
    }

    task = Task {
      defer { self.task = nil }

      let session = try await Current.sessionRefresher(currentSession.session.refreshToken)
      try await update(session)
      return session
    }

    return try await task!.value
  }

  func update(_ session: Session) async throws {
    try await Current.localStorage.storeSession(StoredSession(session: session))
  }

  func remove() async {
    await Current.localStorage.deleteSession()
  }
}

extension GoTrueLocalStorage {
  fileprivate func getSession() async throws -> StoredSession? {
    try await retrieve(key: "supabase.session").flatMap {
      try JSONDecoder.goTrue.decode(StoredSession.self, from: $0)
    }
  }

  fileprivate func storeSession(_ session: StoredSession) async throws {
    try await store(key: "supabase.session", value: JSONEncoder.goTrue.encode(session))
  }

  fileprivate func deleteSession() async {
    try? await remove(key: "supabase.session")
  }
}
