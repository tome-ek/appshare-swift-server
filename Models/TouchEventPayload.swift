//
//  TouchEventPayload.swift
//  PhoneStreamer-iOS
//
//  Created by Tomasz Bartkowski on 12/06/2021.
//

import Quartz

struct TouchEventPayload {
    let sessionId: String
    let x: Double
    let y: Double
    let pressure: Float
    let touchEvent: NSEvent.EventType
}
