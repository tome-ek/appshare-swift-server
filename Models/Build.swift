//
//  Build.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 21.08.21.
//

struct Build: Codable {
    let id: Int
    let bundleIdentifier: String
    let fileName: String
    let bundleName: String
    let iv: String
    let authTag: String
}
