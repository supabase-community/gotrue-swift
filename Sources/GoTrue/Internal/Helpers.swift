import Foundation

func extractParams(from fragment: String) -> [(name: String, value: String)] {
  let components =
    fragment
    .split(separator: "&")
    .map { $0.split(separator: "=") }

  return
    components
    .compactMap {
      $0.count == 2
        ? (name: String($0[0]), value: String($0[1]))
        : nil
    }
}
