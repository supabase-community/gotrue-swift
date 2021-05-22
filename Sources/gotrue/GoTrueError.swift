import Foundation.FoundationErrors

struct GoTrueError: Error {
    var statusCode: Int?
    var message: String?
}

extension GoTrueError: LocalizedError {
    var errorDescription: String? {
        return message
    }
}
