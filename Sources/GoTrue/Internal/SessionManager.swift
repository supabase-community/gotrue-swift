import ComposableKeychain
import Foundation
import GoTrueHTTP
import KeychainAccess

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
    keychain = KeychainClient.live(
      keychain: accessGroup.map { Keychain(service: serviceName ?? "", accessGroup: $0) }
        ?? Keychain(service: serviceName ?? "supabase.gotrue.swift")
    )
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
    keychain.deleteSession()
  }

  nonisolated var storedSession: Session? {
    try? keychain.getSession()
  }
}

extension KeychainClient.Key {
  static var session = Self("supabae_session_key")
}

extension KeychainClient {
  func getSession() throws -> Session? {
    try getData(.session).flatMap {
      try JSONDecoder().decode(Session.self, from: $0)
    }
  }

  func storeSession(_ session: Session) throws {
    try setData(JSONEncoder().encode(session), .session)
  }

  func deleteSession() {
    try? remove(.session)
  }
}
