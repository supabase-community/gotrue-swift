import Foundation

public struct GoTrueError: LocalizedError, Decodable {
  public var message: String?
  public var msg: String?
  public var code: Int?

  private enum CodingKeys: String, CodingKey {
    case message
    case msg
    case code
  }

  public var errorDescription: String? { message ?? msg }
}
