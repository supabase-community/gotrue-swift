import Foundation

public struct GoTrueError: Error {
    public var statusCode: Int?
    public var message: String

    public static var badURL = GoTrueError(message: "Bad URL")
    public static var badCredentials = GoTrueError(message: "Bad credentials")
}

extension GoTrueError: LocalizedError {
    public var errorDescription: String? {
        message
    }
}
