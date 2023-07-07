import AuthenticationServices
import Foundation

extension GoTrueClient {
  @discardableResult
  public func signInWithApple() async throws -> Session {
    let provider = ASAuthorizationAppleIDProvider()
    let request = provider.createRequest()

    let nonce = sha256(randomString())

    request.requestedScopes = [.email, .fullName]
    request.nonce = nonce

    guard let credential = try await AuthorizationController().performRequest(request)
      .credential as? ASAuthorizationAppleIDCredential
    else {
      throw ASAuthorizationError(.invalidResponse)
    }

    guard let idToken = credential.identityToken.flatMap({ String(data: $0, encoding: .utf8) })
    else {
      throw GoTrueError.sessionNotFound
    }

    return try await signInWithIdToken(credentials: .init(
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
