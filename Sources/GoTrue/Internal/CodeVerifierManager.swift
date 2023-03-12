import Foundation
import CryptoKit

class CodeVerifierManager {
    
    /// Convenience function to generate the code verifier
    ///
    /// This method calls createCodeVerifier() and encryptCodeVerifier()
    /// and returns the string to send at the start of the PKCE flow
    func generateCodeVerifier() -> String?{
        guard let codeVerifierData = createCodeVerifier() else { return nil }
        return encryptCodeVerifier(codeVerifierData)
    }
    
    /// Creates a random 25 length string
    ///
    /// This method creates the random string and saves it  as Data in localstorage
    /// and returns it
    func createCodeVerifier() -> Data?{
        let codeVerifier = randomString(length: 25)
        do {
            try Env.localStorage.store(key: "code_verifier", value: Data(codeVerifier.utf8))
            return Data(codeVerifier.utf8)
        } catch {
            print("error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Return the encrypted code verifier as a string
    ///
    /// This method converts encrypts the data to SHA256 and then base64 to send the
    /// value to the server, to be stored. This will later be used for exchangeAuthCode()
    /// on server side
    func encryptCodeVerifier(_ codeVerifierData: Data) -> String? {
        let hashed = SHA256.hash(data: codeVerifierData)
        let hashedData = Data(hashed)
        var base64Encoded = hashedData.base64EncodedString()
        base64Encoded = base64Encoded.replacingOccurrences(of: "+", with: "-")
        base64Encoded = base64Encoded.replacingOccurrences(of: "/", with: "_")
        base64Encoded = base64Encoded.replacingOccurrences(of: "=", with: "")
        return base64Encoded
    }
    
    /// Return the code verifier from localstorage
    ///
    /// This method returns the code verifier in string, unencrypted format for
    /// exchangeAuthCode()
    func getCodeVerifier() -> String? {
        do {
            guard let codeVerifierData = try Env.localStorage.retrieve(key: "code_verifier") else {
                return nil
            }
            return String.init(data: codeVerifierData, encoding: .utf8)
        } catch {
            print("error: \(error.localizedDescription)")
            return nil
        }
    }
    
}
