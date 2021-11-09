import Foundation

public struct GoTrueError: Error {
    public var statusCode: Int?
    public var message: String
}

extension GoTrueError: LocalizedError {
    public var errorDescription: String? {
        return message
    }
}
