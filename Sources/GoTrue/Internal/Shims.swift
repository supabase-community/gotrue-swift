import Get

extension Request {
  init(
    method: HTTPMethod = .get,
    url: String,
    query: [(String, String?)]? = nil,
    body: Encodable? = nil,
    headers: [String: String]? = nil,
    id: String? = nil
  ) {
    self.init(path: url, method: method, query: query, body: body, headers: headers, id: id)
  }
}
