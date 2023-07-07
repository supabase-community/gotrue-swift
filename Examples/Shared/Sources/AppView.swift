import GoTrue
import SwiftUI

struct AppView: View {
  @Environment(\.goTrueClient) private var client
  @State private var session: Session?
  @State private var clientInitialized = false

  var body: some View {
    if clientInitialized {
      NavigationView {
        if let session {
          SessionView(session: session)
        } else {
          List {
            NavigationLink("Auth with Email and Password") {
              AuthWithEmailAndPasswordView()
            }

            NavigationLink("Sign in with Apple") {
              SignInWithAppleView()
            }
          }
          .listStyle(.plain)
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

func stringfy(_ value: some Codable) -> String {
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
