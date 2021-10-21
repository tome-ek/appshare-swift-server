//
//  Firebase.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 24.08.21.
//

import Firebase

enum Firebase {
    static func initialize() {
        do {
            let googleAppID: String = try Env.value(for: "FIR_GOOGLE_APP_ID")
            let gcmSenderID: String = try Env.value(for: "FIR_GCM_SENDER_ID")
            let apiKey: String = try Env.value(for: "FIR_API_KEY")
            let clientID: String = try Env.value(for: "FIR_CLIENT_ID")
            let bundleID: String = try Env.value(for: "FIR_BUNDLE_ID")
            let projectID: String = try Env.value(for: "FIR_PROJECT_ID")
            let storageBucket: String = try Env.value(for: "FIR_STORAGE_BUCKET")
            
            let opts = FirebaseOptions(googleAppID: googleAppID, gcmSenderID: gcmSenderID)
            opts.apiKey = apiKey
            opts.clientID = clientID
            opts.bundleID = bundleID
            opts.projectID = projectID
            opts.storageBucket = storageBucket
            
            FirebaseApp.configure(options: opts)
            
            let app = FirebaseApp.app()
            app?.isDataCollectionDefaultEnabled = false
        } catch {
            print("Failed to parse Firebase config.")
            exit(0)
        }
    }
}
