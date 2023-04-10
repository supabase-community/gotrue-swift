//
//  AuthWithEmailAndPasswordView.swift
//  Examples
//
//  Created by Guilherme Souza on 24/10/22.
//

import GoTrue
import SwiftUI

struct AuthWithEmailAndPasswordView: View {
  @Environment(\.goTrueClient) private var client

  @State private var email = ""
  @State private var password = ""
  @State private var error: Error?
  @State private var isLoading: Bool = false

  var body: some View {
      LoadingView(isShowing: $isLoading) {
          Form {
              Section {
                  TextField("Email", text: $email)
                      .keyboardType(.emailAddress)
                      .textContentType(.emailAddress)
                      .autocorrectionDisabled()
                      .textInputAutocapitalization(.never)
                  SecureField("Password", text: $password)
                      .textContentType(.password)
              }
              
              Section {
                  Button("Sign in") {
                      signInButtonTapped()
                  }
                  
                  Button("Sign up") {
                      signUpButtonTapped()
                  }
              }
              
              if let error {
                  Section {
                      Text(error.localizedDescription)
                          .foregroundColor(.red)
                  }
              }
          }
      }
  }

  private func signInButtonTapped() {
      isLoading = true
    Task {
      do {
        error = nil
        try await client.signIn(email: email, password: password)
      } catch {
        self.error = error
      }
    }
  }

  private func signUpButtonTapped() {
      isLoading = true
    Task {
      do {
        error = nil
        try await client.signUp(email: email, password: password)
      } catch {
        self.error = error
      }
    }
  }
}

struct AuthWithEmailAndPasswordView_Previews: PreviewProvider {
  static var previews: some View {
    AuthWithEmailAndPasswordView()
  }
}
