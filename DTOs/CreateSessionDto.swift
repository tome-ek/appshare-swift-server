//
//  CreateSessionDto.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 13.08.21.
//

import Foundation

struct CreateSessionDto: Codable {
    let id: Int?
    let sessionId: String?
    let buildId: Int?
    let blueprintId: String?
}
