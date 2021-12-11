import Foundation
import Security
import XCTestDynamicOverlay

struct SessionStorage {
  var store: (Session) throws -> Void
  var get: () throws -> Session?
  var delete: () throws -> Void
}

extension SessionStorage {
  static func keychain(serviceName: String? = nil, accessGroup: String? = nil) -> SessionStorage {
    let serviceName = serviceName ?? "supabase.gotrue.swift"
    let key: Data = "supabase_session_key".data(using: .utf8)!
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    return SessionStorage(
      store: { session in
        let data = try encoder.encode(session)
        try Keychain.storeData(data, key: key, serviceName: serviceName, accessGroup: accessGroup)
      },
      get: {
        try Keychain.getData(key: key, serviceName: serviceName, accessGroup: accessGroup).map {
          try decoder.decode(Session.self, from: $0)
        }
      },
      delete: {
        try Keychain.deleteData(key: key, serviceName: serviceName, accessGroup: accessGroup)
      }
    )
  }

  #if DEBUG
    static var failing: SessionStorage {
      SessionStorage(
        store: { _ in
          XCTFail("SessionStorage.store(_:) called but was not implemented.")
        },
        get: {
          XCTFail("SessionStorage.get() called but was not implemented.")
          return .dummy
        },
        delete: {
          XCTFail("SessionStorage.delete() called but was not implemented.")
        }
      )
    }

    static var noop: SessionStorage {
      SessionStorage(
        store: { _ in },
        get: { .dummy },
        delete: {}
      )
    }
  #endif
}

private enum Keychain {

  struct Error: Swift.Error {
    let status: OSStatus
  }

  static func storeData(_ data: Data, key: Data, serviceName: String, accessGroup: String?) throws {
    var query = queryDictionary(key: key, serviceName: serviceName, accessGroup: accessGroup)
    query[kSecValueData] = data

    let status = SecItemAdd(query as CFDictionary, nil)

    if status == errSecSuccess {
      return
    }

    if status == errSecDuplicateItem {
      try updateData(data, key: key, serviceName: serviceName, accessGroup: accessGroup)
    }

    throw Error(status: status)
  }

  static func updateData(_ data: Data, key: Data, serviceName: String, accessGroup: String?) throws
  {
    let query = queryDictionary(key: key, serviceName: serviceName, accessGroup: accessGroup)
    let updateDictionary: CFDictionary = [kSecValueData: data] as CFDictionary

    let status = SecItemUpdate(query as CFDictionary, updateDictionary)

    guard status == errSecSuccess else {
      throw Error(status: status)
    }
  }

  static func getData(key: Data, serviceName: String, accessGroup: String?) throws -> Data? {
    var query = queryDictionary(key: key, serviceName: serviceName, accessGroup: accessGroup)
    query[kSecMatchLimit] = kSecMatchLimitOne
    query[kSecReturnData] = kCFBooleanTrue

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess else {
      throw Error(status: status)
    }

    return result as? Data
  }

  static func deleteData(key: Data, serviceName: String, accessGroup: String?) throws {
    let query = queryDictionary(key: key, serviceName: serviceName, accessGroup: accessGroup)
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess else {
      throw Error(status: status)
    }
  }

  private static func queryDictionary(key: Data, serviceName: String, accessGroup: String?)
    -> [CFString: Any]
  {
    var dictionary: [CFString: Any] = [
      kSecAttrGeneric: key,
      kSecAttrAccount: key,
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: serviceName,
      kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]

    if let accessGroup = accessGroup {
      dictionary[kSecAttrAccessGroup] = accessGroup
    }

    return dictionary
  }
}
