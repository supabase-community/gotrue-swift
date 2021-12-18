import AnyCodable
import Foundation

public struct SignUpOptions {
  public let redirectTo: URL?
  public let data: AnyEncodable?

  public init(redirectTo: URL? = nil, data: AnyEncodable? = nil) {
    self.redirectTo = redirectTo
    self.data = data
  }
}
