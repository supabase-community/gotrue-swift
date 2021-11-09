import Foundation
import AnyCodable

class GoTrueApi {
    var url: String
    var headers: [String: String]

    init(url: String, headers: [String: String]) {
        self.url = url
        self.headers = headers
        self.headers.merge(GoTrueConstants.defaultHeaders) { $1 }
    }

    /// HTTP Methods
    private enum HTTPMethod: String {
        case get = "GET"
        case head = "HEAD"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case connect = "CONNECT"
        case options = "OPTIONS"
        case trace = "TRACE"
        case patch = "PATCH"
    }

    func signUpWithEmail(
        email: String,
        password: String,
        completion: @escaping (Result<(session: Session?, user: User?), Error>) -> Void
    ) {
        guard let url = URL(string: "\(url)/signup") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }

        fetch(url: url, method: .post, parameters: ["email": email, "password": password]) { result in
            do {
                let response = try result.get()
                if let session = try? JSONDecoder().decode(Session.self, from: response) {
                    completion(.success((session, session.user)))
                    return
                }

                let user = try JSONDecoder().decode(User.self, from: response)
                completion(.success((nil, user)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func signInWithEmail(
        email: String,
        password: String, completion: @escaping (Result<Session, Error>) -> Void
    ) {
        guard let url = URL(string: "\(url)/token?grant_type=password") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }

        fetch(url: url, method: .post, parameters: ["email": email, "password": password]) { result in
            do {
                let response = try result.get()
                let session = try JSONDecoder().decode(Session.self, from: response)
                completion(.success(session))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func sendMagicLinkEmail(email: String, completion: @escaping (Result<Any?, Error>) -> Void) {
        guard let url = URL(string: "\(url)/magiclink") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }

        fetch(url: url, method: .post, parameters: ["email": email]) { result in
            switch result {
            case let .success(response):
                completion(.success(response))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func getUrlForProvider(provider: Provider, options: ProviderOptions?) throws -> URL {
        guard var components = URLComponents(string: "\(url)/authorize") else {
            throw GoTrueError(message: "badURL")
        }

        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "provider", value: provider.rawValue))
        if let options = options {
            if let scopes = options.scopes {
                queryItems.append(URLQueryItem(name: "scopes", value: scopes))
            }
            if let redirectTo = options.redirectTo {
                queryItems.append(URLQueryItem(name: "redirect_to", value: redirectTo))
            }
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw GoTrueError(message: "badURL")
        }

        return url
    }

    func refreshAccessToken(refreshToken: String, completion: @escaping (Result<Session, Error>) -> Void) {
        guard let url = URL(string: "\(url)/token?grant_type=refresh_token") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }

        fetch(url: url, method: .post, parameters: ["refresh_token": refreshToken]) { result in
            do {
                let response = try result.get()
                let session = try JSONDecoder().decode(Session.self, from: response)
                completion(.success(session))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func signOut(accessToken: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: "\(url)/logout") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }

        fetch(url: url, method: .post, parameters: [:], headers: ["Authorization": "Bearer \(accessToken)"], completion: completion)
    }

    func updateUser(accessToken: String, emailChangeToken: String?, password: String?, data: [String: Any]? = nil, completion: @escaping (Result<User, Error>) -> Void) {
        guard let url = URL(string: "\(url)/user") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }
        var parameters: [String: Any] = [:]
        if let emailChangeToken = emailChangeToken {
            parameters["email_change_token"] = emailChangeToken
        }

        if let password = password {
            parameters["password"] = password
        }

        if let data = data {
            parameters["data"] = data
        }

        fetch(url: url, method: .put, parameters: parameters, headers: ["Authorization": "Bearer \(accessToken)"]) { result in
            do {
                let response = try result.get()
                let session = try JSONDecoder().decode(User.self, from: response)
                completion(.success(session))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func getUser(accessToken: String, completion: @escaping (Result<User, Error>) -> Void) {
        guard let url = URL(string: "\(url)/user") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }

        fetch(url: url, method: .get, parameters: nil, headers: ["Authorization": "Bearer \(accessToken)"]) { result in
            do {
                let response = try result.get()
                let session = try JSONDecoder().decode(User.self, from: response)
                completion(.success(session))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func fetch(
        url: URL,
        method: HTTPMethod = .get,
        parameters: [String: Any]?,
        headers: [String: String]? = nil,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if var headers = headers {
            headers.merge(self.headers) { $1 }
            request.allHTTPHeaderFields = headers
        } else {
            request.allHTTPHeaderFields = self.headers
        }

        if let parameters = parameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
            } catch {
                completion(.failure(error))
                return
            }
        }

        let dataTask = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) -> Void in
            guard let self = self else { return }

            do {
                if let error = error {
                    throw error
                }

                guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }

                completion(.success(try self.parse(response: data, statusCode: httpResponse.statusCode)))
            } catch {
                completion(.failure(error))
            }
        }

        dataTask.resume()
    }

    private func parse(response: Data, statusCode: Int) throws -> Data {
        if 200..<300 ~= statusCode {
            return response
        }

        let json = try JSONDecoder().decode([String: AnyDecodable].self, from: response)
        let message = json["msg"]?.value ?? json["error_description"]?.value
        throw GoTrueError(statusCode: statusCode, message: message as? String ?? "Unexpected error.")
    }
}
