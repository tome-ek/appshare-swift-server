//
//  MainServer.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 13.08.21.
//

import Foundation
import PerfectHTTP
import PerfectHTTPServer
import PerfectSession
import PerfectRequestLogger
import PerfectLib

protocol ServerType {
    func start()
}

final class Server: ServerType {
    private let server: HTTPServer
    
    private let sessionController: ControllerType
    private let websocketsController: ControllerType
    
    private enum Config {
        static let ServerAddress = "localhost"
        static let ServerName = "appshare-macos"
    }
    
    init(sessionController: ControllerType,
         websocketsController: ControllerType) {
        self.sessionController = sessionController
        self.websocketsController = websocketsController
        
        server = HTTPServer()
        configure()
        addRoutes()
    }
    
    private func configure() {
        SessionConfig.CORS.acceptableHostnames = ["*"]
       
        server.serverName = Config.ServerName
        server.serverAddress = Config.ServerAddress
        server.serverPort = (try? Env.value(for: "SERVER_PORT")) ?? 4000
    }
    
    private func addRoutes() {
        server.addRoutes(sessionController.routes)
        server.addRoutes(websocketsController.routes)
    }
    
    func start() {
        Queue.server.async { [weak self] in
            do {
                try self?.server.start()
            } catch let PerfectError.networkError(err, msg) {
                print("Network error: \(err) \(msg)")
                exit(9)
            } catch {
                print(error)
                exit(9)
            }
        }
    }
}
