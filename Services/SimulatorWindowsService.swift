//
//  SimulatorWindowsService.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 14.08.21.
//

import AXSwift
import PromiseKit
import Quartz

enum SimulatorWindowsServiceError: Error {
    case noWindowCreated
}

typealias WindowNumber = Int
protocol SimulatorWindowsServiceType {
    func createSimulator(_ sessionId: String, forBlueprintId blueprintId: String) -> Promise<WindowNumber>
    func makeKeyWindow(_ windowTitle: String) -> Promise<Void>
    func installApp(_ appPath: String, sessionId: String) -> Promise<Void>
}

@objc class SimulatorWindowsService: NSObject, SimulatorWindowsServiceType {
    private let simulatorApplicationService: SimulatorApplicationServiceType
    private let processesService: ProcessesServiceType

    private var axObserver: AXObserver?
    private var mainWindowChangedClosure: (() -> Void)?

    init(simulatorApplicationService: SimulatorApplicationServiceType,
         processesService: ProcessesServiceType)
    {
        self.simulatorApplicationService = simulatorApplicationService
        self.processesService = processesService

        super.init()

        addAXObserver()
    }

    func makeKeyWindow(_ windowTitle: String) -> Promise<Void> {
        var windowsRef: CFArray?
        AXUIElementCopyAttributeValues(AXUIElementCreateApplication(simulatorApplicationService.simulatorPid),
                                       kAXWindowsAttribute as CFString,
                                       .zero,
                                       .max,
                                       &windowsRef)

        let windows = (windowsRef as? [AXUIElement]) ?? []
        if let window = windows.first(where: { window in
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
            return windowTitle == (titleRef as? String)
        }) {
            AXUIElementSetAttributeValue(
                window,
                kAXMainAttribute as CFString,
                kCFBooleanTrue as CFTypeRef
            )
        }
        return Promise { resolver in
            mainWindowChangedClosure = {
                resolver.fulfill(())
            }
        }
    }

    func createSimulator(_ sessionId: String, forBlueprintId blueprintId: String) -> Promise<WindowNumber> {
        return simulatorWindowNumbers()
            .then { [unowned self] windowNumbers in
                self.processesService.runProcess(cmd: "xcrun simctl clone \(blueprintId) \(sessionId)")
                    .map { windowNumbers }
            }
            .then { [unowned self] windowNumbers in
                self.processesService.runProcess(cmd: "xcrun simctl boot \(sessionId)")
                    .map { windowNumbers }
            }
            .then { windowNumbers in
                after(.seconds(5)).map { windowNumbers }
            }
            .then { [unowned self] startingWindowNumbers -> Promise<([Int], [Int])> in
                self.simulatorWindowNumbers()
                    .map { (startingWindowNumbers, $0) }
            }
            .map { startingWindowNumbers, currentWindowNumbers in
                let difference = currentWindowNumbers.difference(from: startingWindowNumbers)
                    .insertions
                    .first
                switch difference {
                case .insert(offset: _, element: let windowNumber, associatedWith: _):
                    return windowNumber
                default:
                    throw SimulatorWindowsServiceError.noWindowCreated
                }
            }
            .then { [unowned self] windowNumber in
                self.moveWindow(sessionId: sessionId)
                    .map { windowNumber }
            }
    }

    func installApp(_ appPath: String, sessionId: String) -> Promise<Void> {
        return processesService.runProcess(cmd: "xcrun simctl install \(sessionId) \(appPath)")
    }

    private func mainWindowDidChange(_ axElement: AXUIElement) {
        var windowTitleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axElement, kAXTitleAttribute as CFString, &windowTitleRef)
        mainWindowChangedClosure?()
    }

    private func addAXObserver() {
        simulatorApplicationService
            ._simulatorPid
            .done { [weak self] pid in
                guard let self = self else { return }
                self.axObserver = getAXObserverCreate(pid) { (_: AXObserver,
                                                              axElement: AXUIElement,
                                                              _: CFString,
                                                              userData: UnsafeMutableRawPointer?) in
                        guard let userData = userData else { return }
                        let application = Unmanaged<SimulatorWindowsService>
                            .fromOpaque(userData)
                            .takeUnretainedValue()

                        application.mainWindowDidChange(axElement)
                }

                addCFRunLoopSource(self.axObserver!)
                addAXObserverNotification(self.axObserver!,
                                          AXUIElementCreateApplication(pid),
                                          kAXMainWindowChangedNotification,
                                          UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
            }
            .catch { _ in }
    }

    private func simulatorWindowNumbers() -> Promise<[Int]> {
        simulatorApplicationService
            ._simulatorPid
            .map { pid in
                let windows: [(Int, Int, Int)] =
                    NSArray(object: CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID)!)
                        .compactMap { $0 as? NSArray }
                        .reduce([], +)
                        .compactMap { $0 as? [CFString: Any] }
                        .compactMap {
                            ($0[kCGWindowOwnerPID] as! Int, ($0[kCGWindowIsOnscreen] as? Int) ?? 0,
                             ($0[kCGWindowNumber] as? Int) ?? 0)
                        }

                return windows
                    .filter { $0.0 == pid && $0.1 == 1 }
                    .map { $0.2 }
            }
    }

    private func moveWindow(sessionId: String) -> Promise<Void> {
        simulatorWindowsList()
            .map { [unowned self] in self.findSimulatorWindow(for: sessionId, in: $0) }
            .map { window in
                if let window = window {
                    return window
                } else {
                    throw AXError.noValue
                }
            }
            .then { [unowned self] in self.resizeWindowToDesiredSize($0) }
            .then { [unowned self] in self.moveWindowToTopLeftCorner($0) }
    }

    private enum Consts {
        static let simulatorWindowMenuBarHeight: CGFloat = 37
        static let simulatorTargetWidth: CGFloat = 360
        static let systemMenuBarHeight: CGFloat = 23
    }

    private func simulatorWindowsList() -> Promise<[UIElement]> {
        return simulatorApplicationService
            ._simulatorPid
            .map { pid in
                let application = Application(forProcessID: pid)
                let windows = try? application?.windows()
                return windows ?? []
            }
    }

    private func findSimulatorWindow(for sessionId: String, in windows: [UIElement]) -> UIElement? {
        return windows.first(where: { window in
            let title: String? = try? window.attribute(.title)
            return title?.starts(with: sessionId) ?? false
        })
    }

    private func resizeWindowToDesiredSize(_ window: UIElement) -> Promise<UIElement> {
        return Promise { resolver in
            let currentSize: CGSize = (try? window.attribute(.size)) ?? .zero
            let screenHeight = currentSize.height - Consts.simulatorWindowMenuBarHeight
            let aspectRatio = screenHeight / currentSize.width
            let widthDelta = currentSize.width - Consts.simulatorTargetWidth
            let heightDelta = widthDelta * aspectRatio
            let newSize = CGSize(
                width: Consts.simulatorTargetWidth,
                height: floor(currentSize.height - heightDelta)
            )
            try? window.setAttribute(.size, value: newSize)
            resolver.fulfill(window)
        }
    }

    private func moveWindowToTopLeftCorner(_ window: UIElement) -> Promise<Void> {
        try? window.setAttribute(.position, value: CGPoint(x: 0, y: 0))
        return .value
    }
}
