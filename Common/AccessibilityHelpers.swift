//
//  AccessibilityHelpers.swift
//  PhoneStreamer-iOS
//
//  Created by Tomasz Bartkowski on 13/06/2021.
//

import Foundation

func addCFRunLoopSource(_ observer: AXObserver) {
    CFRunLoopAddSource(
        RunLoop.current.getCFRunLoop(),
        AXObserverGetRunLoopSource(observer),
        CFRunLoopMode.defaultMode
    )
}

func removeCFRunLoopSource(_ observer: AXObserver) {
    CFRunLoopRemoveSource(
        RunLoop.current.getCFRunLoop(),
        AXObserverGetRunLoopSource(observer),
        CFRunLoopMode.defaultMode
    )
}

func removeAXObserverAddNotification(
    _ observer: AXObserver,
    _ element: AXUIElement,
    _ notification: String
) {
    let error = AXObserverRemoveNotification(observer, element, notification as CFString)
    guard error == .success || error == .notificationNotRegistered else {
        return
    }
}

func getAXObserverCreate(
    _ application: pid_t,
    _ callback: @escaping ApplicationServices.AXObserverCallback
) -> AXObserver? {
    var observer: AXObserver?
    guard AXObserverCreate(application, callback, &observer) == .success else {
        return nil
    }
    return observer
}

func addAXObserverNotification(
    _ observer: AXObserver,
    _ element: AXUIElement,
    _ notification: String,
    _ refcon: UnsafeMutableRawPointer?
) {
    let error = AXObserverAddNotification(observer, element, notification as CFString, refcon)
    guard error == .success || error == .notificationAlreadyRegistered else {
        return
    }
}
