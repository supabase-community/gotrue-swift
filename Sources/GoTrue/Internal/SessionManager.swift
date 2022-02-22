import Foundation

struct SessionManager {
  private let keychain: KeychainClient

  init(serviceName: String? = nil, accessGroup: String? = nil) {
    keychain = KeychainClient(serviceName: serviceName, accessGroup: accessGroup)
  }

  /// Fetches any available session from the Keychain
  func getSession() -> Session? {
    return try? keychain.getSession()
  }

  func saveSession(_ session: Session) {
    try? keychain.storeSession(session)
  }

  func removeSession() {
    keychain.deleteSession()
  }
}
