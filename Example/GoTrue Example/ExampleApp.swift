import GoTrue
import SwiftUI

@main
struct ExampleApp: App {

  let goTrue = GoTrueClient(
    url: URL(string: "https://insert-your-url-here.com")!,
    headers: ["apiKey": "insert your api key here"]
  )

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.goTrue, goTrue)
    }
  }
}

private enum GoTrueClientEnvironmentKey: EnvironmentKey {
  static var defaultValue: GoTrueClient = .init(url: URL(string: "/")!)
}

extension EnvironmentValues {
  var goTrue: GoTrueClient {
    get { self[GoTrueClientEnvironmentKey.self] }
    set { self[GoTrueClientEnvironmentKey.self] = newValue }
  }
}
