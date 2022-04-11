import SwiftUI

struct SignUpWithEmailAndPasswordView: View {
  static let title = "Sign up with email and password"

  @Environment(\.goTrue) var goTrue

  @State var email = ""
  @State var password = ""
  @State var status: ActionStatus<String, Error> = .idle

  @ViewBuilder
  var body: some View {
    if let value = status.success {
      TextEditor(text: .constant(value))
        .navigationTitle("Signed up")
    } else {
      Form {
        Section {
          TextField("Email", text: $email)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
          SecureField("Password", text: $password)
            .textContentType(.newPassword)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
        }

        Section {
          Button(action: signUpButtonTapped) {
            HStack {
              Spacer()
              if status.isInFlight {
                ProgressView()
              } else {
                Text("Sign up")
              }
              Spacer()
            }
          }
          .allowsHitTesting(!status.isInFlight)
        }

        if let error = status.failure {
          Text(stringfy(error))
            .font(.footnote)
            .foregroundColor(.red)
        }
      }
    }
  }

  private func signUpButtonTapped() {
    Task { @MainActor in
      status = .inFlight

      do {
        let response = try await goTrue.signUp(email: email, password: password)
        status = .success(stringfy(response))
      } catch {
        status = .failure(error)
      }
    }
  }
}

#if DEBUG
  struct SignUpWithEmailAndPasswordView_Previews: PreviewProvider {
    static var previews: some View {
      SignUpWithEmailAndPasswordView()
    }
  }
#endif
