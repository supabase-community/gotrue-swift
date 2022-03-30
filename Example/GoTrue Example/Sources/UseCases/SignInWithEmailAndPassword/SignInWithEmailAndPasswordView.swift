import SwiftUI

struct SignInWithEmailAndPasswordView: View {
  static let title = "Sign in with email and password"

  @Environment(\.goTrue) var goTrue

  @State var email = ""
  @State var password = ""
  @State var status: ActionStatus<String, Error> = .idle

  @ViewBuilder
  var body: some View {
    if let value = status.success {
      TextEditor(text: .constant(value))
    } else {
      Form {
        Section {
          TextField("Email", text: $email)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
          SecureField("Password", text: $password)
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
        }

        Section {
          Button(action: signInButtonTapped) {
            HStack {
              Spacer()
              if status.isInFlight {
                ProgressView()
              } else {
                Text("Sign in")
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

  private func signInButtonTapped() {
    Task { @MainActor in
      status = .inFlight

      do {
        let response = try await goTrue.signIn(email: email, password: password)
        status = .success(stringfy(response))
      } catch {
        status = .failure(error)
      }
    }
  }
}

#if DEBUG
  struct SignInWithEmailAndPasswordView_Previews: PreviewProvider {
    static var previews: some View {
      SignInWithEmailAndPasswordView()
    }
  }
#endif
