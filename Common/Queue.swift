//
//  Queue.swift
//  PhoneStreamer-iOS
//
//  Created by Tomasz Bartkowski on 13/06/2021.
//

import Foundation

enum Queue {
    enum Label: String {
        case server = "com.phonestreamer-io.server"
    }
    
    static let server = DispatchQueue(label: Label.server.rawValue, qos: .default, attributes: .concurrent)
}

public protocol SimpleProtocol {
    func simpleFunc(simpleArg: Int) -> String
}
