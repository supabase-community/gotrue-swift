import GoTrueHTTP
import SwiftUI

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

struct SignUpWithEmailAndPasswordView: View {
  static let title = "Sign up with email and password"

  @Environment(\.goTrue) var goTrue

  @State var email = ""
  @State var password = ""
  @State var status: ActionStatus<String, Error> = .idle

  @ViewBuilder
  var body: some View {
    if let value = status.success {
      ScrollView {
        Text(value)
      }
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
          Text(error.localizedDescription)
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

  private func stringfy(_ response: Paths.Signup.PostResponse) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    var data: Data?

    switch response {
    case .session(let session):
      data = try? encoder.encode(session)
    case .user(let user):
      data = try? encoder.encode(user)
    }

    return data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
  }
}

#if DEBUG
  struct SignUpWithEmailAndPasswordView_Previews: PreviewProvider {
    static var previews: some View {
      SignUpWithEmailAndPasswordView()
    }
  }
#endif
