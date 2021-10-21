//
//  SimulatorEventsService.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 14.08.21.
//

import Foundation

protocol SimulatorEventsServiceType {
    func handleEvent(_ eventPayload: String)
}

struct SimulatorEventsService: SimulatorEventsServiceType {
    private let simulatorApplicationService: SimulatorApplicationServiceType
    private let simulatorWindowsService: SimulatorWindowsServiceType
    private let sessionRepository: SessionRepositoryType
    
    init(simulatorApplicationService: SimulatorApplicationServiceType,
         simulatorWindowsService: SimulatorWindowsServiceType,
         sessionRepository: SessionRepositoryType) {
        self.simulatorApplicationService = simulatorApplicationService
        self.simulatorWindowsService = simulatorWindowsService
        self.sessionRepository = sessionRepository
    }
    
    func handleEvent(_ eventPayload: String) {
        if let event = Event.from(payload: eventPayload) {
            self.simulatorApplicationService
                .activate()
                .done {
                    let pid: pid_t = simulatorApplicationService.simulatorPid
                    switch event {
                    case let .key(payload):
                        Queue.keyEvent.async {
                            simulatorWindowsService
                                .makeKeyWindow(payload.sessionId)
                                .done { CGEvent.keyEventsSequence(fromPayload: payload).forEach { event in
                                        event.postToPid(pid)
                                        usleep(1000)
                                    }
                                }
                                .catch { _ in }
                            }
                    case let .touch(payload):
                        sessionRepository
                            .getSession(id: payload.sessionId)
                            .done { session in
                                guard let windowNumber = session.windowNumber else { return }
                                let cgEvent = CGEvent.mouseEvent(fromPayload: payload, windowNumber: windowNumber, scale: 1)
                                cgEvent?.postToPid(pid)
                            }
                            .cauterize()
                    }
                }
                .catch { error in }
        }
        
    }
}
