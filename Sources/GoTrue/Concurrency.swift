#if compiler(>=5.5) && canImport(_Concurrency)
  @available(iOS 13.0.0, macOS 10.15, tvOS 13.0, *)
  extension GoTrueClient {

    public func onAuthStateChange() -> AsyncStream<(AuthChangeEvent, Session?)> {
      var subscription: Subscription?
      let onTermination = {
        subscription?.unsubscribe()
        subscription = nil
      }

      return AsyncStream { continuation in
        continuation.onTermination = { @Sendable _ in onTermination() }

        subscription = onAuthStateChange { event, session in
          continuation.yield((event, session))
        }
      }
    }

    public func signUp(email: String, password: String) async throws -> User {
      try await withCheckedThrowingContinuation { continuation in
        signUp(email: email, password: password) { result in
          continuation.resume(with: result)
        }
      }
    }

    public func signIn(email: String, password: String) async throws -> Session {
      try await withCheckedThrowingContinuation { continuation in
        signIn(email: email, password: password) { result in
          continuation.resume(with: result)
        }
      }
    }

    public func signIn(email: String) async throws {
      try await withCheckedThrowingContinuation { continuation in
        signIn(email: email) { result in
          continuation.resume(with: result)
        }
      }
    }

    public func update(
      emailChangeToken: String? = nil, password: String? = nil, data: [String: Any]? = nil
    ) async throws -> User {
      try await withCheckedThrowingContinuation { continuation in
        update(emailChangeToken: emailChangeToken, password: password, data: data) { result in
          continuation.resume(with: result)
        }
      }
    }

    public func getSessionFromUrl(url: String) async throws -> Session {
      try await withCheckedThrowingContinuation { continuation in
        getSessionFromUrl(url: url) { result in
          continuation.resume(with: result)
        }
      }
    }

    public func refreshSession() async throws -> Session {
      try await withCheckedThrowingContinuation { continuation in
        refreshSession { result in
          continuation.resume(with: result)
        }
      }
    }

    public func signOut() async throws {
      try await withCheckedThrowingContinuation { continuation in
        signOut { error in
          error.map(continuation.resume(throwing:)) ?? continuation.resume()
        }
      }
    }
  }
#endif
