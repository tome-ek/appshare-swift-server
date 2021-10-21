//
//  Session.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 13.08.21.
//

import GRDB

struct Session: Codable, FetchableRecord, PersistableRecord {
    let id: Int
    let sessionId: String
    let buildId: Int
    let blueprintId: String
    let windowNumber: Int?
    
    init(id: Int, sessionId: String, buildId: Int, blueprintId: String, windowNumber: Int?) {
        self.id = id
        self.sessionId = sessionId
        self.buildId = buildId
        self.blueprintId = blueprintId
        self.windowNumber = windowNumber
    }
    
    init(from session: Session, windowNumber: Int) {
        self.id = session.id
        self.sessionId = session.sessionId
        self.buildId = session.buildId
        self.blueprintId = session.blueprintId
        self.windowNumber = windowNumber
    }
}
