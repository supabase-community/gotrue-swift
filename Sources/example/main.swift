import Foundation
import gotrue

func main() {
    let semaphore = DispatchSemaphore(value: 0)

    let client = GoTrueClient(url: "https://galflylhyokjtdotwnde.supabase.co/auth/v1")

    client.signIn(email: "email@example.com", password: "password") { result in
        switch result {
        case let .success(session):
            print(session)
        case let .failure(error):
            print(error.localizedDescription)
        }
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
//        if event == .SIGNED_IN {
//            client.signOut { result in
//                switch result {
//                case let .success(session):
//                    print(session as Any)
//                case let .failure(error):
//                    print(error.localizedDescription)
//                }
//                semaphore.signal()
//            }
//        }
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
