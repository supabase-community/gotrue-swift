//
//  ExamplesApp.swift
//  Shared
//
//  Created by Guilherme Souza on 28/06/22.
//

import SwiftUI
import GoTrue

@main
struct ExamplesApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                List {
                    NavigationLink("Sign in with Google") {
                        SignInWithGoogleExampleView()
                    }
                }
                .navigationTitle("Examples")
            }
        }
    }
}

let gotrue = GoTrueClient(
    url: URL(string: "https://{PROJECT_ID}.supabase.co/auth/v1")!,
    headers: ["apikey": "{PROJECT_API_KEY}"]
)

