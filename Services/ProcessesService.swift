//
//  ProcessesServie.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 15.08.21.
//

import PromiseKit
import Quartz

protocol ProcessesServiceType {
    func runProcess(cmd: String) -> Promise<Void>
}

struct ProcessesService: ProcessesServiceType {
    private enum Consts {
        static let shellPath = "/bin/zsh"
        static let shellArguments = ["-c"]
    }
    
    func runProcess(cmd: String) -> Promise<Void> {
        Promise { resolver in
            let process = Process()
            process.launchPath = Consts.shellPath
            process.arguments = Consts.shellArguments + [cmd]
            process.terminationHandler = { _ in
                resolver.fulfill(())
            }
            process.launch()
        }
    }
}
