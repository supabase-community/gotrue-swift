import Foundation

public enum GoTrueError: Error {
  case missingExpClaim
  case sessionNotFound
  case api(APIError)

  public struct APIError: Error, Decodable {
    public var message: String?
    public var msg: String?
    public var code: Int?
    public var error: String?
    public var errorDescription: String?

    private enum CodingKeys: String, CodingKey {
      case message
      case msg
      case code
      case error
      case errorDescription = "error_description"
    }
  }
}
