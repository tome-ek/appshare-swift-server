//
//  FilesService.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 22.08.21.
//

import ZIPFoundation
import Foundation
import PromiseKit

protocol FilesServiceType {
    func writeData(_ data: Data?, toFileAtPath path: String) -> Promise<String>
    func unzipBundle(_ build: Build, path: String) -> Promise<String>
    func cleanup(_ build: Build) -> Promise<Void>
}

struct FilesService: FilesServiceType {
    func writeData(_ data: Data?, toFileAtPath path: String) -> Promise<String> {
        FileManager.default.createFile(
            atPath: path,
            contents: data,
            attributes: nil
        )
        return .value(path)
    }
    
    func unzipBundle(_ build: Build, path: String) -> Promise<String> {
        let sourceURL = URL(fileURLWithPath: path)
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory())
        do {
            try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.unzipItem(at: sourceURL, to: destinationURL)
            return .value(NSTemporaryDirectory() + build.bundleName + ".app")
        } catch {
            return Promise(error: error)
        }
    }
    
    func cleanup(_ build: Build) -> Promise<Void> {
        try? FileManager.default.removeItem(atPath: NSTemporaryDirectory() + build.bundleName + ".app")
        try? FileManager.default.removeItem(atPath: NSTemporaryDirectory() + build.bundleName + ".zip")
        return .value
    }
}
