//
//  SignInWithGoogleExampleView.swift
//  Shared
//
//  Created by Guilherme Souza on 28/06/22.
//

import SwiftUI
import GoTrue

struct SignInWithGoogleExampleView: View {
    @State var user: User?

    @ViewBuilder
    var body: some View {
        if let user = user {
            Form {
                Section {
                    Text(stringfy(user))
                        .multilineTextAlignment(.leading)
                }

                Section {
                    Button("Sign out") {
                        Task {
                            try await gotrue.signOut()
                            self.user = nil
                        }
                    }
                }
            }
        } else {
            Button("Sign in with Google", action: signInWithGoogleTapped)
                .buttonStyle(.borderedProminent)
                .padding()
                .onOpenURL { url in
                    Task {
                        try await gotrue.session(from: url)
                        self.user = gotrue.session?.user
                    }
                }
                .onAppear {
                    self.user = gotrue.session?.user
                }
        }
    }

    func signInWithGoogleTapped() {
        do {
            let url = try gotrue.signIn(provider: .google)
            UIApplication.shared.open(url)
        } catch {
            print("Error sign in with google", error)
        }
    }
}

func stringfy<T: Encodable>(_ value: T) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try! encoder.encode(value)
    return String(data: data, encoding: .utf8)!
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SignInWithGoogleExampleView()
    }
}
