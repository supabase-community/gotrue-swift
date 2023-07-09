import AuthenticationServices
import Foundation

extension GoTrueClient {
  /// Signs a user in using native Apple Login.
  ///
  /// This method is experimental as the underlying `signInWithIdToken` method is experimental.
  @_spi(Experimental)
  @discardableResult
  public func signInWithApple() async throws -> Session {
    let provider = ASAuthorizationAppleIDProvider()
    let request = provider.createRequest()

    let nonce = sha256(randomString())

    request.requestedScopes = [.email, .fullName]
    request.nonce = nonce

    let handle = SignInWithAppHandle(nonce: nonce, client: self)
    let authorization = try await AuthorizationController().performRequest(request)

    return try await handle.process(authorization)
  }

  @_spi(Experimental)
  public func signInWithApple(_ request: ASAuthorizationAppleIDRequest) -> SignInWithAppHandle {
    let nonce = request.nonce ?? sha256(randomString())
    let handle = SignInWithAppHandle(nonce: nonce, client: self)
    request.nonce = nonce
    return handle
  }
}

@_spi(Experimental)
public struct SignInWithAppHandle {
  let nonce: String?
  let client: GoTrueClient

  @discardableResult
  public func process(_ authorization: ASAuthorization) async throws -> Session {
    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      throw ASAuthorizationError(.invalidResponse)
    }

    guard let idToken = credential.identityToken.flatMap({ String(data: $0, encoding: .utf8) })
    else {
      throw GoTrueError.missingOrInvalidIdToken
    }

    return try await client.signInWithIdToken(credentials: .init(
      provider: .apple,
      idToken: idToken,
      nonce: nonce
    ))
  }
}

final class AuthorizationController: NSObject,
  ASAuthorizationControllerPresentationContextProviding,
  ASAuthorizationControllerDelegate
{
  var continuation: CheckedContinuation<ASAuthorization, Error>?

  func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
    UIWindow()
  }

  func performRequest(_ request: ASAuthorizationRequest) async throws -> ASAuthorization {
    let controller = ASAuthorizationController(authorizationRequests: [request])
    controller.presentationContextProvider = self
    controller.delegate = self
    controller.performRequests()

    return try await withCheckedThrowingContinuation { self.continuation = $0 }
  }

  func authorizationController(
    controller _: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    continuation?.resume(returning: authorization)
  }

  func authorizationController(
    controller _: ASAuthorizationController,
    didCompleteWithError error: Error
  ) {
    continuation?.resume(throwing: error)
  }
}
