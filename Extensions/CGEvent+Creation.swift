//
//  CGEvent+Creation.swift
//  PhoneStreamer-iOS
//
//  Created by Tomasz Bartkowski on 13/06/2021.
//

import Foundation
import Quartz

extension CGEvent {
    static func mouseEvent(fromPayload payload: TouchEventPayload, windowNumber: Int, scale: Double) -> CGEvent? {
        let mouseEvent = NSEvent.mouseEvent(
            with: payload.touchEvent,
            location: NSPoint(x: payload.x * scale, y: screenOffset(for: payload.touchEvent) - (payload.y * scale)),
            modifierFlags: .init(rawValue: 0),
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: payload.pressure
        )
        
        let cgEvent = mouseEvent?.cgEvent
        cgEvent?.flags = CGEventFlags(rawValue: 0)
        return cgEvent
    }
    
    static func keyEventsSequence(fromPayload payload: KeyEventPayload) -> [CGEvent] {
        var events = [CGEvent]()
        let (mainKeyDownEvent, mainKeyUpEvent) = keyPair(payload.keyCode)
        
        var shiftDownEvent: CGEvent?
        var shiftUpEvent: CGEvent?
        var altDownEvent: CGEvent?
        var altUpEvent: CGEvent?
        var flags: [CGEventFlags] = []
        
        if payload.hasShift {
            let (localShiftDownEvent, localShiftUpEvent) = keyPair(CGKeyCode(56))
            shiftDownEvent = localShiftDownEvent
            shiftUpEvent = localShiftUpEvent
            flags.append(.maskShift)
        }
        
        if payload.hasAlt {
            let (localAltDownEvent, localAltUpEvent) = keyPair(CGKeyCode(58))
            altDownEvent = localAltDownEvent
            altUpEvent = localAltUpEvent
            flags.append(.maskAlternate)
        }
        
        mainKeyDownEvent?.flags = CGEventFlags(flags)
        mainKeyUpEvent?.flags = CGEventFlags(flags)
        
        if let shiftDownEvent = shiftDownEvent {
            events.append(shiftDownEvent)
        }
        if let altDownEvent = altDownEvent {
            events.append(altDownEvent)
        }
        if let mainKeyDownEvent = mainKeyDownEvent {
            events.append(mainKeyDownEvent)
        }
        if let mainKeyUpEvent = mainKeyUpEvent {
            events.append(mainKeyUpEvent)
        }
        if let altUpEvent = altUpEvent {
            events.append(altUpEvent)
        }
        if let shiftUpEvent = shiftUpEvent {
            events.append(shiftUpEvent)
        }

        return events
    }
    
    private static let src = CGEventSource(stateID: .hidSystemState)
    
    private static func keyPair(_ keyCode: CGKeyCode) -> (CGEvent?, CGEvent?) {
        let keyDownEvent = CGEvent(
            keyboardEventSource: src,
            virtualKey: keyCode,
            keyDown: true
        )
        let keyUpEvent = CGEvent(
            keyboardEventSource: src,
            virtualKey: keyCode,
            keyDown: false
        )
        return(keyDownEvent, keyUpEvent)
    }
    
    private static func screenOffset(for event: NSEvent.EventType) -> Double {
        if case NSEvent.EventType.leftMouseDragged = event {
            return 993
        }
        return 1013
    }
}
