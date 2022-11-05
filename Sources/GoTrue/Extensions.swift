import Get

extension AuthResponse {
  public var user: User? {
    if case let .user(user) = self { return user }
    return nil
  }

  public var session: Session? {
    if case let .session(session) = self { return session }
    return nil
  }
}

extension Request {
  func withAuthorization(_ token: String, type: String = "Bearer") -> Self {
    var copy = self
    var headers = copy.headers ?? [:]
    headers["Authorization"] = "\(type) \(token)"
    copy.headers = headers
    return copy
  }
}
