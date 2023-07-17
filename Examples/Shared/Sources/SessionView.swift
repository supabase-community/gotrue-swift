//
//  SessionView.swift
//  Examples
//
//  Created by Guilherme Souza on 24/10/22.
//

import GoTrue
import SwiftUI

struct SessionView: View {
  @Environment(\.goTrueClient) private var client

  let session: Session

  var body: some View {
    ScrollView {
      Text(stringfy(session))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    .navigationTitle("Session")
    .toolbar {
      ToolbarItem {
        Button("Sign out") {
          Task {
            try? await client.signOut()
          }
        }
      }
    }
  }
}

struct SessionView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      SessionView(
        session: .init(
          accessToken: "placeholder",
          tokenType: "bearer",
          expiresIn: 3600,
          refreshToken: "refreshToken",
          user: User(
            id: UUID(),
            appMetadata: [:],
            userMetadata: [:],
            aud: "",
            createdAt: Date(),
            updatedAt: Date()
          )
        ))
    }
  }
}
