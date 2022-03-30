import ComposableKeychain
import Foundation
import GoTrueHTTP
import KeychainAccess

struct SessionNotFound: Error {}

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
  var storedSession: () -> Session?
  var session: () async throws -> Session
  var update: (_ session: Session) async throws -> Void
  var remove: () async -> Void
}

extension SessionManager {
  static var live: Self {
    let instance = LiveSessionManager()
    return Self(
      storedSession: { instance.storedSession },
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

    guard let currentSession = try Current.keychain.getSession() else {
      throw SessionNotFound()
    }

    if currentSession.isValid {
      return currentSession.session
    }

    self.task = Task {
      defer { self.task = nil }

      let session = try await Current.sessionRefresher(currentSession.session.refreshToken)
      try update(session)
      return session
    }

    return try await task!.value
  }

  func update(_ session: Session) throws {
    try Current.keychain.storeSession(StoredSession(session: session))
  }

  func remove() {
    Current.keychain.deleteSession()
  }

  /// Returns the currently stored session without checking if it's still valid.
  nonisolated var storedSession: Session? {
    try? Current.keychain.getSession()?.session
  }
}

extension KeychainClient.Key {
  static var session = Self("supabase.session")
  static var expirationDate = Self("supabase.session.expiration_date")
}

extension KeychainClient {
  func getSession() throws -> StoredSession? {
    try getData(.session).flatMap {
      try JSONDecoder().decode(StoredSession.self, from: $0)
    }
  }

  func storeSession(_ session: StoredSession) throws {
    try setData(JSONEncoder().encode(session), .session)
  }

  func deleteSession() {
    try? remove(.session)
  }
}
