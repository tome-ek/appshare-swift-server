//
//  HTTPResponse+Error.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 13.08.21.
//

import ASHSimulatorKit
import PerfectHTTP

extension HTTPResponse {
    func error(_ error: Error) {
        if let error = error as? ApiError {
            setBody(string: error.json ?? "")
            completed(status: error.status)
        } else if let error = error as? SimulatorKitError {
            setBody(string: error.json ?? "")
            completed(status: .internalServerError)
        } else {
            setBody(string: error.json ?? "")
            completed(status: .internalServerError)
        }
    }
}
