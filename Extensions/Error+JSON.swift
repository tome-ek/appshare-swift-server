//
//  Error+JSON.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 13.08.21.
//

import ASHSimulatorKit
import Foundation

extension Error {
    var json: String? {
        return try? ["error": ["message": localizedDescription]].jsonEncodedString()
    }
}

extension SimulatorKitError {
    var json: String? {
        return try? ["error": ["message": message]].jsonEncodedString()
    }
}
