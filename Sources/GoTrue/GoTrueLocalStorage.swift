import Foundation
import KeychainAccess

public protocol GoTrueLocalStorage {
  func store(key: String, value: Data) async throws
  func retrieve(key: String) async throws -> Data?
  func remove(key: String) async throws
}

public actor KeychainLocalStorage: GoTrueLocalStorage {
  let keychain: Keychain

  public init(service: String, accessGroup: String?) {
    if let accessGroup = accessGroup {
      keychain = Keychain(service: service, accessGroup: accessGroup)
    } else {
      keychain = Keychain(service: service)
    }
  }

  public func store(key: String, value: Data) async throws {
    try keychain.set(value, key: key)
  }

  public func retrieve(key: String) async throws -> Data? {
    try keychain.getData(key)
  }

  public func remove(key: String) async throws {
    try keychain.remove(key)
  }
}
