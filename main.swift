//
//  main.swift
//  PhoneStreamer-iOS
//
//  Created by Tomasz Bartkowski on 12/06/2021.
//

import AXSwift
import Foundation
import Quartz

checkIsProcessTrusted(prompt: true)

Firebase.initialize()

let server = DependenciesContainer.shared.compositionRoot
server.start()

RunLoop.main.run()
