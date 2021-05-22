import gotrue
import Foundation

func main() {
    let semaphore = DispatchSemaphore(value: 0)

    let client = GoTrueClient()

    client.onAuthStateChange = { event in
        print(event)
    }

    client.signUp(email: "1@example.com", password: "password") { result in
        switch result {
        case let .success(session):
            print(session)
        case let .failure(error):
            print(error.localizedDescription)
        }
        semaphore.signal()
    }
    
    semaphore.wait()
}

main()
