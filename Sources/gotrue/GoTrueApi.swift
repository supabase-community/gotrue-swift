import Foundation.NSURL

class GoTrueApi {
    var url: String
    var headers: [String: String]
    var cookieOptions: CookieOptions?

    init(url: String, headers: [String: String], cookieOptions: CookieOptions?) {
        self.url = url
        self.headers = headers
        self.cookieOptions = cookieOptions
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

    func signUpWithEmail(email: String, password: String, completion: @escaping (Result<Session?, Error>) -> Void) {
        guard let url = URL(string: "\(url)/signup") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }

        fetch(url: url, method: .post, parameters: ["email": email, "password": password]) { result in
            switch result {
            case let .success(response):
                guard let dict: [String: Any] = response as? [String: Any], let session = Session(from: dict) else {
                    completion(.failure(GoTrueError(message: "failed to parse response")))
                    return
                }
                completion(.success(session))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func signInWithEmail(email: String, password: String, completion: @escaping (Result<Session?, Error>) -> Void) {
        guard let url = URL(string: "\(url)/token?grant_type=password") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }

        fetch(url: url, method: .post, parameters: ["email": email, "password": password]) { result in
            switch result {
            case let .success(response):
                guard let dict: [String: Any] = response as? [String: Any], let session = Session(from: dict) else {
                    completion(.failure(GoTrueError(message: "failed to parse response")))
                    return
                }
                completion(.success(session))
            case let .failure(error):
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

    func refreshAccessToken(refreshToken: String, completion: @escaping (Result<Session?, Error>) -> Void) {
        guard let url = URL(string: "\(url)/token?grant_type=refresh_token") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }

        fetch(url: url, method: .post, parameters: ["refresh_token": refreshToken]) { result in
            switch result {
            case let .success(response):
                guard let dict: [String: Any] = response as? [String: Any], let session = Session(from: dict) else {
                    completion(.failure(GoTrueError(message: "failed to parse response")))
                    return
                }
                completion(.success(session))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func signOut(accessToken: String, completion: @escaping (Result<Any?, Error>) -> Void) {
        guard let url = URL(string: "\(url)/logout") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }

        fetch(url: url, method: .post, parameters: [:], headers: ["Authorization": "Bearer \(accessToken)"]) { result in
            switch result {
            case let .success(response):
                completion(.success(response))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func updateUser(accessToken: String,emailChangeToken: String?, password: String?, data: [String:Any]? = nil, completion: @escaping (Result<User, Error>) -> Void) {
        guard let url = URL(string: "\(url)/user") else {
            completion(.failure(GoTrueError(message: "badURL")))
            return
        }
        var parameters: [String:Any] = [:]
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
            switch result {
            case let .success(response):
                guard let dict: [String: Any] = response as? [String: Any], let user = User(from: dict) else {
                    completion(.failure(GoTrueError(message: "failed to parse response")))
                    return
                }
                completion(.success(user))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func fetch(url: URL, method: HTTPMethod = .get, parameters: [String: Any]?, headers: [String: String]? = nil, completion: @escaping (Result<Any, Error>) -> Void) {
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

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request, completionHandler: { [unowned self] (data, response, error) -> Void in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let resp = response as? HTTPURLResponse {
                if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        do {
                            completion(.success(try self.parse(response: json, statusCode: resp.statusCode)))
                        } catch {
                            completion(.failure(error))
                            return
                        }
                    } catch {
                        if let dataString = String(data: data, encoding: .utf8) {
                            completion(.success(dataString))
                            return
                        } else {
                            completion(.failure(error))
                            return
                        }
                    }
                }
            } else {
                completion(.failure(GoTrueError(message: "failed to get response")))
            }

        })

        dataTask.resume()
    }

    private func parse(response: Any, statusCode: Int) throws -> Any {
        if statusCode == 200 || 200 ..< 300 ~= statusCode {
            return response
        } else if let dict = response as? [String: Any], let message = dict["msg"] as? String {
            throw GoTrueError(statusCode: statusCode, message: message)
        } else if let dict = response as? [String: Any], let message = dict["error_description"] as? String {
            throw GoTrueError(statusCode: statusCode, message: message)
        } else {
            return response
        }
    }
}
