//
//  SessionController.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 12.08.21.
//

import ASHSimulatorKit
import PerfectHTTP
import PromiseKit

struct SessionController: ControllerType {
    let routes: Routes

    private let sessionRepository: SessionRepositoryType
    private let buildRepository: BuildRepositoryType
    private let storageService: StorageServiceType
    private let cryptoService: CryptoServiceType
    private let filesService: FilesServiceType
    private let simulatorKit: SimulatorKitType

    init(sessionRepository: SessionRepositoryType,
         buildRepository: BuildRepositoryType,
         storageService: StorageServiceType,
         cryptoService: CryptoServiceType,
         filesService: FilesServiceType,
         simulatorKit: SimulatorKitType)
    {
        self.sessionRepository = sessionRepository
        self.buildRepository = buildRepository
        self.storageService = storageService
        self.cryptoService = cryptoService
        self.filesService = filesService
        self.simulatorKit = simulatorKit

        let startSession = Route(method: HTTPMethod.post, uri: "/sessions") { req, res in
            guard let dto = try? req.decode(CreateSessionDto.self) else {
                res.error(GeneralApiError.bodyDecodingFailure)
                return
            }

            sessionRepository.createSession(dto: dto)
                .then { session in
                    simulatorKit
                        .createSimulator(session.sessionId, forBlueprintId: session.blueprintId)
                        .map { (session, $0) }
                }
                .then { session, windowNumber -> Promise<Session> in
                    let session = Session(from: session, windowNumber: windowNumber)
                    return sessionRepository.updateSession(session: session)
                }
                .done { session in
                    buildRepository
                        .getBuild(id: session.buildId)
                        .then { build in
                            storageService.getBuildBundle(build)
                                .map { bundleData in (bundleData, build) }
                        }
                        .then { bundleData, build in
                            cryptoService.decryptBundle(bundleData, ofBuild: build)
                                .map { decryptedData in (decryptedData, build) }
                        }
                        .then { decryptedData, build in
                            filesService.writeData(
                                decryptedData,
                                toFileAtPath: NSTemporaryDirectory() + build.bundleName + ".zip"
                            )
                            .map { archivePath in (archivePath, build) }
                        }
                        .then { archivePath, build in
                            filesService.unzipBundle(build, path: archivePath)
                                .map { bundlePath in (bundlePath, build) }
                        }
                        .then { bundlePath, build in
                            simulatorKit.installApp(bundlePath, sessionId: session.sessionId)
                                .map { build }
                        }
                        .then { build in
                            filesService.cleanup(build)
                        }
                        .done {
                            try res.setBody(json: session)
                            res.completed(status: .created)
                        }
                        .catch { error in
                            res.error(error)
                        }
                }
                .catch { error in
                    res.error(error)
                }
        }

        let getSession = Route(method: HTTPMethod.get, uri: "/sessions/{id}") { req, res in
            sessionRepository.getSession(id: req.urlVariables["id"] ?? "0")
                .done { session in
                    try res.setBody(json: session)
                    res.completed(status: .ok)
                }
                .catch { res.error($0) }
        }
        
        let deleteSession = Route(method: HTTPMethod.delete, uri: "/sessions/{id}") { req, res in
            guard let id = req.urlVariables["id"] else {
                res.error(GeneralApiError.invalidArgument("id"))
                return
            }
            sessionRepository.getSession(id: id)
                .then { simulatorKit.closeSimulator($0.sessionId) }
                .then { sessionRepository.deleteSession(id: id) }
                .done { res.completed(status: .noContent) }
                .catch { res.error($0) }
        }

        routes = Routes(
            baseUri: "api/v1",
            routes: [
                startSession,
                getSession,
                deleteSession
            ]
        )
    }
}
