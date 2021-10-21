//
//  ApiService.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 21.08.21.
//

import Alamofire
import Foundation
import PromiseKit

protocol ApiServiceType {
    func fetch<T: Codable>(_ path: String) -> Promise<T?>
}

struct ApiService: ApiServiceType {
    private let apiUrl: String
    
    init() {
        if let apiUrl: String = try? Env.value(for: "API_URL") {
            self.apiUrl = apiUrl
        } else {
            print("API_URL not found in config.")
            exit(1)
        }
    }
    
    func fetch<T: Codable>(_ path: String) -> Promise<T?> {
        var headers: HTTPHeaders = []
        if let apiToken: String = try? Env.value(for: "API_TOKEN") {
            let authorizationHeader: HTTPHeader = .authorization(bearerToken: apiToken)
            headers.add(authorizationHeader)
        }
        
        return Promise { r in
            AF.request("\(apiUrl)/\(path)", headers: headers)
                .responseDecodable { r.fulfill($0.value) }
        }
    }
}
