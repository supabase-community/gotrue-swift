enum ActionStatus<Success, Failure: Error> {
  case idle, inFlight
  case success(Success)
  case failure(Failure)

  var isInFlight: Bool {
    if case .inFlight = self { return true }
    return false
  }

  var success: Success? {
    if case .success(let value) = self { return value }
    return nil
  }

  var failure: Failure? {
    if case .failure(let error) = self { return error }
    return nil
  }
}
