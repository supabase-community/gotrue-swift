//
//  SignInWithAppleView.swift
//  Examples
//
//  Created by Guilherme Souza on 07/07/23.
//

import AuthenticationServices
import CryptoKit
import SwiftUI
@_spi(Experimental) import GoTrue

struct SignInWithAppleView: View {
  @Environment(\.goTrueClient) private var client
  @State var nonce: String?

  var body: some View {
    SignInWithAppleButton { request in
//      self.nonce = sha256(randomString())
//      request.nonce = nonce
      request.requestedScopes = [.email, .fullName]
    } onCompletion: { result in
      Task {
        do {
          guard let credential = try result.get().credential as? ASAuthorizationAppleIDCredential
          else {
            return
          }

          guard let idToken = credential.identityToken
            .flatMap({ String(data: $0, encoding: .utf8) })
          else {
            return
          }

          try await client.signInWithIdToken(
            credentials: .init(
              provider: .apple,
              idToken: idToken/*,
              nonce: self.nonce*/
            )
          )
        } catch {
          dump(error)
        }
      }
    }
    .fixedSize()
  }
}

func randomString(length: Int = 32) -> String {
  precondition(length > 0)
  var randomBytes = [UInt8](repeating: 0, count: length)
  let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
  if errorCode != errSecSuccess {
    fatalError(
      "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
    )
  }

  let charset: [Character] =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

  let nonce = randomBytes.map { byte in
    // Pick a random character from the set, wrapping around if needed.
    charset[Int(byte) % charset.count]
  }

  return String(nonce)
}

func sha256(_ input: String) -> String {
  let inputData = Data(input.utf8)
  let hashedData = SHA256.hash(data: inputData)
  let hashString = hashedData.compactMap {
    String(format: "%02x", $0)
  }.joined()

  return hashString
}

struct SignInWithApple_PreviewProvider: PreviewProvider {
  static var previews: some View {
    SignInWithAppleView()
  }
}
