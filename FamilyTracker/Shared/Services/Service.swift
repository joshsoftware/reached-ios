//
//  Service.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 03/03/21.
//

import Foundation
#if os(watchOS)
import WatchKit
#endif
import Alamofire

enum APIError: Error {
    case networkError
    case authenticationError
    case unknownError(Error?)
    case parsingError
    case timedOutError
    case serverError
    case notSupported
    var description: String {
        switch self {
            case .authenticationError:
                return "Unautherised Access"
            case .networkError:
                return "Can not connect to internet"
            case .parsingError:
                return "Not able to pase response"
            case .timedOutError:
                return "Not able to get response in time"
            case .serverError:
                return "SomeThing went wrong"
            case .unknownError(let error):
                return error?.localizedDescription ?? "SomeThing went wrong"
            case .notSupported:
                return "Not supported"
                
        }
    }
}

class Service: NSObject {
    public static let shared: Service = Service()
    private override init() {}
    // MARK: - Server Connections Method

    func request<T: Decodable>(url: String, httpMethodType: String, parameters: [[String: AnyObject]]?, completion: @escaping (Result<T,APIError>) -> Void) {
        guard let newUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: newUrl) else {
            print("Invalid URL")
            return
        }
        //TODO: Refactor this code to get URL Request directly
        var request = URLRequest(url: url)
        request.httpMethod = httpMethodType
        request.timeoutInterval = 60

        if let params = parameters {
            do {
                if let data = try JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions(rawValue: 0)) as NSData? {
                    request.httpBody = data as Data
                }
            } catch {
                
            }
        }
        //
        AF.request(request)
            .validate()
            .validate(contentType: ["application/json"])
            .responseJSON { result in
                switch result.result {
                    case .success:
                        if let response = result.data {
                            do {
                                let decoder = JSONDecoder()
                                let responseData = try decoder.decode(T.self, from: response)
                                return completion(.success(responseData))
                            } catch _ {
                                completion(.failure(.parsingError))
                            }
                        }
                        completion(.failure(.parsingError))
                    case .failure(let error):
                        handleAuthError (response: result.response, completion: completion)
                        //TODO: Handle Other errors too
                        let nsError = parseNSError(error)
                        if  nsError.code == -1009 {
                            completion(.failure(.networkError))
                        }
                        if let nsError = error.underlyingError as? URLError {
                            switch nsError.code {
                                case .timedOut:
                                    completion(.failure(.timedOutError))
                                default:
                                    break
                            }
                        }
                        completion(.failure(.unknownError(error)))
                }
            }
        
        func parseNSError(_ error: Error) -> NSError {
            return error as NSError
        }
        
        func handleAuthError(response: HTTPURLResponse?, completion: @escaping (Result<T,APIError>) -> Void) {
            guard let response = response else {
                return completion(.failure(.unknownError(nil)))
            }
            switch response.statusCode {
                case 401:
                    return completion(.failure(.authenticationError))
                case 500:
                    return completion(.failure(.serverError))
                default:
                    return completion(.failure(.unknownError(nil)))
            }
        }
        
    }
}
