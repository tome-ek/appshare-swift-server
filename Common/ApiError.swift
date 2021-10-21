//
//  ApiError.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 13.08.21.
//

import Foundation
import PerfectHTTP

protocol ApiError: Error {
    var message: String { get }
    var json: String? { get }
    var status: HTTPResponseStatus { get }
}

extension ApiError {
    var json: String? {
        return try? ["error": ["message": message]].jsonEncodedString()
    }
    
    var status: HTTPResponseStatus {
        return .badRequest
    }
}

typealias ArgumentName = String
typealias EntityName = String

enum GeneralApiError: ApiError {
    case bodyDecodingFailure
    case databaseReadFailure
    case databaseWriteFailure
    case notFound(EntityName)
    case invalidArgument(ArgumentName)
    
    var message: String {
        switch self {
        case .bodyDecodingFailure:
            return "Failed to decode request body."
        case .databaseReadFailure:
            return "Failed to read from database."
        case .databaseWriteFailure:
            return "Failed to write to database."
        case let .notFound(name):
            return "The '\(name)' does not exist."
        case let .invalidArgument(name):
            return "The argument '\(name)' has an incorrect format."
        }
    }
    
    var status: HTTPResponseStatus {
        switch self {
        case .invalidArgument:
            return .badRequest
        case .notFound:
            return .notFound
        default:
            return .internalServerError
        }
    }
}
