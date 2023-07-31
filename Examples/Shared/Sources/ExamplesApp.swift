//
//  ExamplesApp.swift
//  Shared
//
//  Created by Guilherme Souza on 28/06/22.
//

import GoTrue
import SwiftUI

@main
struct ExamplesApp: App {
  var body: some Scene {
    WindowGroup {
      AppView()
    }
  }
}

private enum GoTrueEnvironmentKey: EnvironmentKey {
    static let defaultValue = GoTrueClient(url: SUPABASE_URL, headers: ["apikey": SUPABASE_API_KEY], flowType: .pkce)
}

extension EnvironmentValues {
  var goTrueClient: GoTrueClient {
    get { self[GoTrueEnvironmentKey.self] }
    set { self[GoTrueEnvironmentKey.self] = newValue }
  }
}
