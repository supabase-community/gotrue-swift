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

  @State var siwaHandle: SignInWithAppHandle?

  var body: some View {
    VStack {
      Button("Sign in with Apple") {
        Task {
          do {
            try await client.signInWithApple()
          } catch {
            dump(error)
          }
        }
      }

      SignInWithAppleButton { request in
        request.requestedScopes = [.email, .fullName]
        siwaHandle = client.signInWithApple(request)
      } onCompletion: { result in
        Task {
          do {
            try await siwaHandle?.process(result.get())
          } catch {
            dump(error)
          }
        }
      }
      .fixedSize()
    }
  }
}

#Preview {
  SignInWithAppleView()
}
