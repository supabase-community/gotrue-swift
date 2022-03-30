import GoTrueHTTP
import SwiftUI

struct SignInWithMagicLinkView: View {
  static let title = "Sign in with magic link"

  @Environment(\.goTrue) var goTrue

  @State var email = ""
  @State var status: ActionStatus<Void, Error> = .idle

  @ViewBuilder
  var body: some View {
    Form {
      Section {
        TextField("Email", text: $email)
          .keyboardType(.emailAddress)
          .textContentType(.emailAddress)
          .textInputAutocapitalization(.never)
          .disableAutocorrection(true)
      }

      Section {
        Button(action: sendMagicLinkButtonTapped) {
          HStack {
            Spacer()
            if status.isInFlight {
              ProgressView()
            } else {
              Text("Send magic link")
            }
            Spacer()
          }
        }
        .allowsHitTesting(!status.isInFlight)
      }

      switch status {
      case .success:
        Text("Email sent with magic link.")
      case .failure(let error):
        Text(stringfy(error))
          .font(.footnote)
          .foregroundColor(.red)
      default:
        EmptyView()
      }
    }
    .onOpenURL { url in
      // TODO: handle URL and retrieve session.
    }
  }

  private func sendMagicLinkButtonTapped() {
    Task { @MainActor in
      status = .inFlight

      do {
        try await goTrue.sendMagicLink(params: OTPParams(email: email))
        status = .success(())
      } catch {
        status = .failure(error)
      }
    }
  }
}

#if DEBUG
  struct SignInWithMagicLinkView_Previews: PreviewProvider {
    static var previews: some View {
      SignInWithMagicLinkView()
    }
  }
#endif
