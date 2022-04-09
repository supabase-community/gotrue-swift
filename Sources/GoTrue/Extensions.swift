extension SessionOrUser {

  public var user: User? {
    if case .user(let user) = self { return user }
    return nil
  }

  public var session: Session? {
    if case .session(let session) = self { return session }
    return nil
  }
}
