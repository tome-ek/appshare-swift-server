//
//  SimulatorApplicationService.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 13.08.21.
//

import PromiseKit
import Quartz

protocol SimulatorApplicationServiceType {
    func activate() -> Promise<Void>
    var simulatorPid: pid_t { get }
    var _simulatorPid: Promise<pid_t> { get }
}

enum SimulatorApplicationError: Error {
    case simulatorProcessLaunchFailure
}

final class SimulatorApplicationService: SimulatorApplicationServiceType {
    private(set) var simulatorPid: pid_t
    
    private enum Consts {
        static let simulatorBundleIdentifier = "com.apple.iphonesimulator"
        static let launchSimulatorCommand = "open -a Simulator"
    }
    
    private let processesService: ProcessesServiceType
    private var simulatorApplication: NSRunningApplication!
    private let _pidPromise = Promise<pid_t>.pending()
    var _simulatorPid: Promise<pid_t> {
        return _pidPromise.promise
    }
    
    init(processesService: ProcessesServiceType) {
        self.processesService = processesService
        
        simulatorPid = -1
        launchSimulatorApplication()
            .done { [weak self] runningApplication in
                self?.simulatorApplication = runningApplication
                self?.simulatorPid = runningApplication.processIdentifier
                self?._pidPromise.resolver.fulfill(runningApplication.processIdentifier)
            }
            .catch { error in
                print(error.localizedDescription)
            }
    }
    
    func activate() -> Promise<Void> {
        if simulatorApplication.isActive {
            return .value
        }
        return Promise { resolver in
            simulatorApplication.activate(options: .activateIgnoringOtherApps)
            Queue.process.asyncAfter(deadline: .now() + .nanoseconds(250_000)) {
                resolver.fulfill(())
            }
        }
    }
    
    private func launchSimulatorApplication() -> Promise<NSRunningApplication> {
        if let runningApplication = runningSimulatorApplication() {
            return Promise.value(runningApplication)
        }
        
        return processesService.runProcess(cmd: Consts.launchSimulatorCommand)
            .map { _ in
                if let runningApplication = NSWorkspace.shared.runningApplications.first(where: {
                    ($0.bundleIdentifier ?? "") == Consts.simulatorBundleIdentifier
                }) {
                    return runningApplication
                } else {
                    throw SimulatorApplicationError.simulatorProcessLaunchFailure
                }
            }
    }
    
    
    private func runningSimulatorApplication() -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first(where: {
            ($0.bundleIdentifier ?? "") == Self.Consts.simulatorBundleIdentifier
        })
    }
}
