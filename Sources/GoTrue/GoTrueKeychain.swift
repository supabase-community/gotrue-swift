import Foundation
import Security

class GoTrueKeychain {
    // Parameters for storage, set with sensible defaults in `init`
    var serviceName: String
    var accessGroup: String?
    
    // Private constants
    private let key: Data = "supabase_session_key".data(using: .utf8)!
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(serviceName: String? = nil, accessGroup: String? = nil) {
        self.serviceName = serviceName ?? "supabase.gotrue.swift"
        self.accessGroup = accessGroup
    }
    
    func storeSession(_ session: Session) throws {
        let data = try encoder.encode(session)
        storeData(data)
    }
    
    func getSession() throws -> Session? {
        if let encodedData = getData() {
            return try decoder.decode(Session.self, from: encodedData)
        } else {
            return nil
        }
    }
    
    func deleteSession() {
        deleteData()
    }
}

extension GoTrueKeychain {
    
    /// Stores given data in the keychain.
    /// - Parameter data: Data to store
    /// - Returns: Boolean, `true` if the operation was successul.
    @discardableResult
    private func storeData(_ data: Data) -> Bool {
        var query = setUpQueryDictionary()
        query[kSecValueData] = data
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            return true
        } else if status == errSecDuplicateItem {
            return updateData(data)
        } else {
            return false
        }
    }
    
    /// Updates a keychain item, used when `storeData` fails with a duplicate item.
    /// - Parameter data: Data to store.
    /// - Returns: Boolean, `true` if the operation succeeded.
    @discardableResult
    private func updateData(_ data: Data) -> Bool {
        let query = setUpQueryDictionary()
        let updateDictionary: CFDictionary = [kSecValueData: data] as CFDictionary
        
        let status = SecItemUpdate(query as CFDictionary, updateDictionary)
        
        return status == errSecSuccess
    }
    
    /// Gets any available data in the keychain.
    /// - Returns: Boolean, `true` if the operation succeeded.
    @discardableResult
    private func getData() -> Data? {
        var query = setUpQueryDictionary()
        query[kSecMatchLimit] = kSecMatchLimitOne // Limit results to one
        query[kSecReturnData] = kCFBooleanTrue
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        return (status == errSecSuccess) ? (result as? Data) : nil
    }
    
    /// Deletes the stored session from the keychain.
    /// - Returns: Boolean, `true` if the operation succeeded.
    @discardableResult
    private func deleteData() -> Bool {
        let query = setUpQueryDictionary()
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    /// Generates a query dictionary for keychain operations.
    /// - Returns: `[CFString: Any]` that can be type-casted to a `CFDictionary`.
    /// By default sets these parameters:
    ///  - Class = Generic Password
    ///  - Accessibility = After first unlock this device only
    ///  Customizable parameters (customized through class initialization):
    ///  - Service Name
    ///  - Access Group
    ///  Static Parameters
    ///  - Storage Key
    private func setUpQueryDictionary() -> [CFString: Any] {
        var dictionary: [CFString: Any] = [
            kSecAttrGeneric: key,
            kSecAttrAccount: key,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        if let accessGroup = accessGroup {
            dictionary[kSecAttrAccessGroup] = accessGroup
        }
        
        return dictionary
    }
}
