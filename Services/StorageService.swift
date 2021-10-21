//
//  StorageService.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 22.08.21.
//

import FirebaseStorage
import PromiseKit

protocol StorageServiceType {
    func getBuildBundle(_ build: Build?) -> Promise<Data?>
}

struct StorageService: StorageServiceType {
    private enum Consts {
        static let bundlesDirectory = "bundles"
        static let maxDownloadSize: Int64 = 512000000
    }
    
    func getBuildBundle(_ build: Build?) -> Promise<Data?> {
        guard let build = build, let bucketUrl: String = try? Env.value(for: "BUCKET_URL") else {
            return .value(nil)
        }
        let storageRef = Storage.storage(url: bucketUrl).reference()
        let buildRef = storageRef.child(Consts.bundlesDirectory)
            .child(build.bundleIdentifier)
            .child(build.fileName)
        
        return Promise { resolver in
            buildRef.getData(maxSize: Consts.maxDownloadSize) { (data, error) in
                if let error = error {
                    resolver.reject(error)
                } else {
                    resolver.fulfill(data)
                }
            }
        }
    }
}


