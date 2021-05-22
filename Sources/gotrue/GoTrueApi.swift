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

    private func fetch(url: URL, method: HTTPMethod = .get, parameters: [String: Any]?, completion: @escaping (Result<Any, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

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
                        completion(.success(try self.parse(response: try JSONSerialization.jsonObject(with: data, options: []), statusCode: resp.statusCode)))
                    } catch {
                        completion(.failure(error))
                        return
                    }
                }
            } else {}

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
