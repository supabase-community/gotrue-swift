import GoTrue
import SwiftUI
import AuthenticationServices
import Combine

class SignInViewModel: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
    
    func signInGoogle(client: GoTrueClient) {
        
        /* Config callback url from Google Cloud Console with following guide
         https://supabase.com/docs/guides/auth/social-login/auth-google#find-your-callback-url
         */
        
        // Need to config Url Type in Info.plist match with below Scheme
        let schemeUrl = "supabase"
        
        do {
            let url = try client.getOAuthSignInURL(
                provider: Provider.google
                
                // Need to config scheme url in Supabase Auth console panel
                ,redirectTo: URL(string: "\(schemeUrl)://auth")
            )
            let handler: ASWebAuthenticationSession.CompletionHandler = { (url, error) in
                if let error = error {
                    NSLog("Error \(error)")
                } else if let url = url {
                    Task {
                        try await client.session(from: url)
                    }
                }
            }
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: schemeUrl,
                completionHandler: handler
            )
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        } catch {
            NSLog("Error \(error)")
        }
    }
}

struct AppView: View {
    @Environment(\.goTrueClient) private var client
    @State private var session: Session?
    @State private var clientInitialized = false
    @StateObject var signInModel = SignInViewModel()
    
  var body: some View {
    if clientInitialized {
      NavigationView {
        if let session {
          SessionView(session: session)
        } else {
            Section {
                List {
                  NavigationLink("Auth with Email and Password") {
                      AuthWithEmailAndPasswordView()
                  }
                  NavigationLink("Auth with Email and OTP") {
                      AuthWithEmailAndOTP()
                  }
                    Button("Google Sign In") {
                        signInModel.signInGoogle(client: client)
                    }
                }
                .listStyle(.plain)
            }
          .navigationTitle("Examples")
        }
      }
      .task { await observeSession() }
    } else {
      ProgressView()
        .task {
          await client.initialize()
          clientInitialized = true
        }
    }
  }

  private func observeSession() async {
    for await _ in client.authEventChange {
      session = try? await client.session
    }
  }
    
}

func stringfy<T: Codable>(_ value: T) -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  let data = try? encoder.encode(value)
  return data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
}

struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView()
  }
}
