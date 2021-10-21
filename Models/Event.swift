//
//  Event.swift
//  PhoneStreamer-iOS
//
//  Created by Tomasz Bartkowski on 12/06/2021.
//

import Quartz

enum Event {
    case touch(TouchEventPayload)
    case key(KeyEventPayload)
    
    private enum EventType: String {
        case touchDown = "0"
        case touchUp = "1"
        case touchMove = "2"
        case key = "3"
    }

    private static func parseEvent(_ input: String) -> Event? {
        if input.count < 7 { return nil }
        guard
            let eventType =
            EventType(rawValue: String(input[String.Index(utf16Offset: 6, in: input)]))
        else { return nil }

        func parsePoint(_ input: String) -> (Double, Double) {
            return
                (Double(input[
                    String.Index(utf16Offset: 7, in: input) ... String
                        .Index(utf16Offset: 13, in: input)
                ]) ?? 0,
                Double(input[
                    String.Index(utf16Offset: 14, in: input) ... String
                        .Index(utf16Offset: 20, in: input)
                ]) ?? 0
            )
        }

        func touchEventForInput(
            _ input: String,
            _ sessionId: String,
            _ pressure: Float,
            _ eventType: NSEvent.EventType
        ) -> Event {
            let (x, y) = parsePoint(input)
            let payload = TouchEventPayload(
                sessionId: sessionId,
                x: x,
                y: y,
                pressure: pressure,
                touchEvent: eventType
            )
            return .touch(payload)
        }

        let sessionId = String(input.prefix(6))
        switch eventType {
        case .touchMove:
            if input.count < 20 { return nil }
            return touchEventForInput(input, sessionId, 1, .leftMouseDragged)
        case .touchDown:
            if input.count < 20 { return nil }
            return touchEventForInput(input, sessionId, 1, .leftMouseDown)
        case .touchUp:
            if input.count < 20 { return nil }
            return touchEventForInput(input, sessionId, 0, .leftMouseUp)
        case .key:
            if input.count < 11 { return nil }
            let payload = KeyEventPayload(
                sessionId: sessionId,
                keyCode: UInt16(input[
                    String.Index(utf16Offset: 7, in: input) ... String
                        .Index(utf16Offset: 9, in: input)
                ])!,
                hasShift: input[String.Index(utf16Offset: 10, in: input)] == "1",
                hasAlt: input[String.Index(utf16Offset: 11, in: input)] == "1"
            )
            return .key(payload)
        }
    }
    
    static func from(payload: String) -> Event? {
        return parseEvent(payload)
    }
}
