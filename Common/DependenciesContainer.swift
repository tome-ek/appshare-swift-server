//
//  DependenciesContainer.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 13.08.21.
//

import ASHSimulatorKit
import PerfectWebSockets
import Swinject

final class DependenciesContainer {
    static let shared = DependenciesContainer()

    private enum ControllerName {
        static let session = "Session"
        static let websocket = "Websocket"
    }

    final lazy var compositionRoot: ServerType = {
        container.resolve(ServerType.self)!
    }()

    private let container = Container()

    private init() {
        container.register(ServerType.self) { r in
            Server(sessionController: r.resolve(ControllerType.self, name: ControllerName.session)!,
                   websocketsController: r.resolve(ControllerType.self, name: ControllerName.websocket)!)
        }
        
        container.register(ControllerType.self, name: ControllerName.session) { r in
            SessionController(
                sessionRepository: r.resolve(SessionRepositoryType.self)!,
                buildRepository: r.resolve(BuildRepositoryType.self)!,
                storageService: r.resolve(StorageServiceType.self)!,
                cryptoService: r.resolve(CryptoServiceType.self)!,
                filesService: r.resolve(FilesServiceType.self)!,
                simulatorKit: r.resolve(SimulatorKitType.self)!
            )
        }

        container.register(WebSocketSessionHandler.self) { r in
            WebSocketsController.Handler(simulatorKit: r.resolve(SimulatorKitType.self)!)
        }

        container.register(ControllerType.self, name: ControllerName.websocket) { r in
            WebSocketsController(websocketsSessionHandler: r.resolve(WebSocketSessionHandler.self)!)
        }
        
        container.register(SessionRepositoryType.self) { r in
            SessionRepository(databaseConnection: r.resolve(DatabaseConnectable.self)!)
        }

        container.register(ApiServiceType.self) { _ in
            ApiService()
        }

        container.register(BuildRepositoryType.self) { r in
            BuildRepository(apiService: r.resolve(ApiServiceType.self)!)
        }

        container.register(FilesServiceType.self) { _ in
            FilesService()
        }

        container.register(StorageServiceType.self) { _ in
            StorageService()
        }

        container.register(CryptoServiceType.self) { _ in
            CryptoService()
        }

        container.register(SimulatorKitType.self) { _ in
            SimulatorKit()
        }

        container.register(DatabaseConnectable.self) { _ in
            DatabaseConnection()
        }
        .inObjectScope(.container)
    }
}
