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

/// Global GoTrueClient instance.
let gotrue = GoTrueClient(url: SUPABASE_URL, headers: ["apikey": SUPABASE_API_KEY])
