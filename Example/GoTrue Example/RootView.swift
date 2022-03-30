import SwiftUI

struct RootView: View {
  var body: some View {
    NavigationView {
      List {
        NavigationLink(
          SignUpWithEmailAndPasswordView.title,
          destination: SignUpWithEmailAndPasswordView.init
        )
      }
      .navigationTitle("Use cases")
    }
  }
}

#if DEBUG
  struct RootView_Previews: PreviewProvider {
    static var previews: some View {
      RootView()
    }
  }
#endif
