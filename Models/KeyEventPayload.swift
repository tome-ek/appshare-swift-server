//
//  KeyEventData.swift
//  PhoneStreamer-iOS
//
//  Created by Tomasz Bartkowski on 12/06/2021.
//

import Foundation

struct KeyEventPayload {
    let sessionId: String
    let keyCode: UInt16
    let hasShift: Bool
    let hasAlt: Bool
}
