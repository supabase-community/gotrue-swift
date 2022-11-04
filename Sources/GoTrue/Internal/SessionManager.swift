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

    guard let currentSession = try Current.localStorage.getSession() else {
      throw GoTrueError.sessionNotFound
    }

    if currentSession.isValid {
      return currentSession.session
    }

    task = Task {
      defer { self.task = nil }

      let session = try await Current.sessionRefresher(currentSession.session.refreshToken)
      try update(session)
      return session
    }

    return try await task!.value
  }

  func update(_ session: Session) throws {
    try Current.localStorage.storeSession(StoredSession(session: session))
  }

  func remove() {
    Current.localStorage.deleteSession()
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
