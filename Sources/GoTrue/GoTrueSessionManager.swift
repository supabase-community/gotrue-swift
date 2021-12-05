import Foundation

/// A class for managing the storage of the user's session. Also handles updating from any legacy storage.
class GoTrueSessionManager {
    private let keychain: GoTrueKeychain
    
    init(serviceName: String? = nil, accessGroup: String? = nil) {
        keychain = GoTrueKeychain(serviceName: serviceName, accessGroup: accessGroup)
    }
    
    /// Checks for any `UserDefaults` stored session and migrates it to the keychain for improved security.
    public func checkForOldStorage() {
        if let session = UserDefaults.standard.value(Session.self, forKey: "\(GoTrueConstants.defaultStorageKey).session") {
            saveSession(session)
            UserDefaults.standard.removeObject(forKey: "\(GoTrueConstants.defaultStorageKey).session")
        }
    }
    
    /// Fetches any available session from the Keychain
    public func getSession() -> Session? {
        return try? keychain.getSession()
    }
    
    public func saveSession(_ session: Session) {
        try? keychain.storeSession(session)
    }
    
    public func removeSession() {
        keychain.deleteSession()
    }
    
}
