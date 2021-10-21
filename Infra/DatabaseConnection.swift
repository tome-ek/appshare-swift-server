//
//  DatabaseConnection.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 13.08.21.
//

import Foundation
import GRDB

protocol DatabaseConnectable {
    var writer: DatabaseWriter { get }
}

final class DatabaseConnection: DatabaseConnectable {
    let writer: DatabaseWriter
    
    init() {
        do {
            let databaseFilename: String = try Env.value(for: "DATABSE_FILENAME")
            let databasePath = Bundle.main.resourcePath?.appending("/\(databaseFilename)")
            if let path = databasePath, !FileManager.default.fileExists(atPath: path) {
                FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
            } else {
                print("Databse already exists. No need to create a new one.")
            }
            
            if let path = databasePath {
                let dbPool = try DatabasePool(path: path)
                self.writer = dbPool
            } else {
                print("Failed to connect to database.")
                exit(9)
            }
        } catch {
            print(error)
            exit(9)
        }
        createTables()
    }
    
    private func createTables() {
        writer.asyncWriteWithoutTransaction { db in
            try? db.create(table: "session", temporary: false, ifNotExists: true, body: { t in
                t.column("id", .integer).primaryKey().notNull()
                t.column("sessionId", .text).notNull()
                t.column("buildId", .integer).notNull()
                t.column("blueprintId", .text).notNull()
                t.column("windowNumber", .integer)
            })
        }
    }
}
