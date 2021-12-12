import Foundation

extension Array where Element == URLQueryItem {
  subscript(query: String) -> String? {
    first(where: { $0.name == query })?.value
  }
}
