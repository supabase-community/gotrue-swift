//
//  SignInWithAppleView.swift
//  Examples
//
//  Created by Guilherme Souza on 07/07/23.
//

import AuthenticationServices
import CryptoKit
import SwiftUI

struct SignInWithAppleView: View {
  @Environment(\.goTrueClient) private var client

  var body: some View {
    Button("Sign in with Apple") {
      Task {
        do {
          try await client.signInWithApple()
        } catch {
          dump(error)
        }
      }
    }
  }
}

#Preview {
  SignInWithAppleView()
}
