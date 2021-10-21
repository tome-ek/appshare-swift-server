//
//  WebSocketsController.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 14.08.21.
//

import ASHSimulatorKit
import PerfectHTTP
import PerfectWebSockets

struct WebSocketsController: ControllerType {
    struct Handler: WebSocketSessionHandler {
        private let simulatorKit: SimulatorKitType
        
        init(simulatorKit: SimulatorKitType) {
            self.simulatorKit = simulatorKit
        }
        
        let socketProtocol: String? = nil
        func handleSession(request req: HTTPRequest, socket: WebSocket) {
            socket.readStringMessage { payload, _, _ in
                guard let payload = payload else {
                    socket.close()
                    return
                }
                simulatorKit.handleInputEvent(payload)
                self.handleSession(request: req, socket: socket)
            }
        }
    }
    
    let routes: Routes
    private let websocketsSessionHandler: WebSocketSessionHandler
    
    init(websocketsSessionHandler: WebSocketSessionHandler) {
        self.websocketsSessionHandler = websocketsSessionHandler
        
        let upgradeConnection = Route(method: HTTPMethod.get, uri: "/websockets") { (req, res) in
            WebSocketHandler { _, _ in websocketsSessionHandler }
                .handleRequest(request: req, response: res)
        }
     
        routes = Routes(
            baseUri: "api/v1",
            routes: [
                upgradeConnection,
            ]
        )
    }
}
