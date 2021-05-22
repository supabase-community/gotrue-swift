import Foundation
import gotrue

func main() {
    let semaphore = DispatchSemaphore(value: 0)

    let client = GoTrueClient(url: "https://satishbabariya-gotrue-dart-vg6x-9999.githubpreview.dev")

    client.signIn(email: "email@example.com", password: "secret") { result in
        switch result {
        case let .success(session):
            print(session)
        case let .failure(error):
            print(error.localizedDescription)
        }
        semaphore.signal()
    }

//    client.signIn(provider: .google, options: ProviderOptions(redirectTo: "xx", scopes: "xx")) { result in
//        switch result {
//        case let .success(r):
//            print(r)
//        case let .failure(error):
//            print(error.localizedDescription)
//        }
//    }
//
//    client.signIn(email: "email@example.com") { result in
//        switch result {
//        case let .success(data):
//            print(data)
//        case let .failure(error):
//            print(error.localizedDescription)
//        }
//        semaphore.signal()
//    }

    client.onAuthStateChange = { event in
        print(event)
    }

//    client.signUp(email: "1@example.com", password: "password") { result in
//        switch result {
//        case let .success(session):
//            print(session)
//        case let .failure(error):
//            print(error.localizedDescription)
//        }
//        semaphore.signal()
//    }

    semaphore.wait()
}

main()
