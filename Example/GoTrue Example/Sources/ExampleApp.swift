import GoTrue
import SwiftUI

@main
struct ExampleApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}

private enum GoTrueClientEnvironmentKey: EnvironmentKey {
  static var defaultValue: GoTrueClient = GoTrueClient(
    url: Secrets.supabaseURL.appendingPathComponent("/auth/v1"),
    headers: ["apiKey": Secrets.supabaseKey]
  )
}

extension EnvironmentValues {
  var goTrue: GoTrueClient {
    get { self[GoTrueClientEnvironmentKey.self] }
    set { self[GoTrueClientEnvironmentKey.self] = newValue }
  }
}
