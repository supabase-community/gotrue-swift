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
    url: URL(string: "https://insert-your-url-here.com")!,
    headers: ["apiKey": "insert your api key here"]
  )
}

extension EnvironmentValues {
  var goTrue: GoTrueClient {
    get { self[GoTrueClientEnvironmentKey.self] }
    set { self[GoTrueClientEnvironmentKey.self] = newValue }
  }
}
