//
//  CryptoService.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 22.08.21.
//

import CryptoKit
import Foundation
import PromiseKit

protocol CryptoServiceType {
    func decryptBundle(_ bundleData: Data?, ofBuild build: Build?) -> Promise<Data?>
}

struct CryptoService: CryptoServiceType {
    func decryptBundle(_ bundleData: Data?, ofBuild build: Build?) -> Promise<Data?> {
        guard let build = build, let data = bundleData else { return .value(nil) }
        do {
            let keyStr = Data(base64Encoded: try Env.value(for: "AES_KEY"))!
            let key = SymmetricKey(data: keyStr)
            let nonce = Data(base64Encoded: build.iv)!
            let tag = Data(base64Encoded: build.authTag)!
       
            let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonce), ciphertext: data, tag: tag)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return .value(decryptedData)
        } catch {
            return Promise(error: error)
        }
    }
}
