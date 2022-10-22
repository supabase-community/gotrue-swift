import Foundation

public protocol GoTrueLocalStorage {
  func store(key: String, value: Data) async throws
  func retrieve(key: String) async throws -> Data?
}

actor KeychainLocalStorage: GoTrueLocalStorage {
  func store(key: String, value: Data) async throws {
  }

  func retrieve(key: String) async throws -> Data? {
    nil
  }
}
