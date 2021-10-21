//
//  SessionRepository.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 13.08.21.
//

import GRDB
import PromiseKit

protocol SessionRepositoryType {
    func createSession(dto: CreateSessionDto) -> Promise<Session>
    func updateSession(session: Session) -> Promise<Session>
    func getSession(id: String) -> Promise<Session>
    func deleteSession(id: String) -> Promise<Void>
}

struct SessionRepository: SessionRepositoryType {
    private enum Config {
        static let cacheCapacity = 5
    }

    private let databaseConnection: DatabaseConnectable
    private let cache: LRUCache<String, Session>

    init(
        databaseConnection: DatabaseConnectable,
        cache: LRUCache<String, Session> = LRUCache(capacity: Config.cacheCapacity)
    ) {
        self.databaseConnection = databaseConnection
        self.cache = cache
    }

    enum CreateSessionError: ApiError {
        case missingId
        case missingSessionId
        case missingBuildId
        case missingBlueprintId

        var message: String {
            return "Missing field: '\(fieldName)'"
        }
        
        private var fieldName: String {
            switch self {
            case .missingId:
                return "id"
            case .missingSessionId:
                return "sessionId"
            case .missingBuildId:
                return "buildId"
            case .missingBlueprintId:
                return "blueprintId"
            }
        }
    }

    func createSession(dto: CreateSessionDto) -> Promise<Session> {
        guard let id = dto.id else {
            return Promise(error: CreateSessionError.missingId)
        }
        guard let sessionId = dto.sessionId else {
            return Promise(error: CreateSessionError.missingSessionId)
        }
        guard let buildId = dto.buildId else {
            return Promise(error: CreateSessionError.missingBuildId)
        }
        guard let blueprintId = dto.blueprintId else {
            return Promise(error: CreateSessionError.missingBlueprintId)
        }

        let session = Session(id: id,
                              sessionId: sessionId,
                              buildId: buildId,
                              blueprintId: blueprintId,
                              windowNumber: nil)

        return Promise { resolver in
            databaseConnection.writer.asyncWrite({ db in
                try session.save(db)
            }, completion: { _, result in
                switch result {
                case .success:
                    resolver.fulfill(session)
                case let .failure(error):
                    resolver.reject(error)
                }
            })
        }
    }

    func updateSession(session: Session) -> Promise<Session> {
        return Promise { resolver in
            databaseConnection.writer.asyncWrite({ db in
                try session.update(db)
            }, completion: { _, result in
                switch result {
                case .success:
                    resolver.fulfill(session)
                case let .failure(error):
                    resolver.reject(error)
                }
            })
        }
    }

    func getSession(id: String) -> Promise<Session> {
        if let session = cache[id] {
            return .value(session)
        }

        return Promise { r in
            guard let sessionId = Int(id) else {
                r.reject(GeneralApiError.invalidArgument("id"))
                return
            }
            databaseConnection.writer.asyncRead { result in
                switch result {
                case let .success(db):
                    guard let session = try? Session.filter(Column("id") == sessionId).fetchOne(db) else {
                        r.reject(GeneralApiError.notFound("Session"))
                        return
                    }
                    self.cache[id] = session
                    r.fulfill(session)
                case .failure:
                    r.reject(GeneralApiError.databaseReadFailure)
                }
            }
        }
    }
    
    func deleteSession(id: String) -> Promise<Void> {
        return Promise { r in
            guard let sessionId = Int(id) else {
                r.reject(GeneralApiError.invalidArgument("id"))
                return
            }
            cache[id] = nil
            databaseConnection.writer.asyncWrite({ db in
                try Session.deleteOne(db, key: sessionId)
            }, completion: { _, result in
                switch result {
                case .success:
                    r.fulfill(())
                case let .failure(error):
                    r.reject(error)
                }
            })
        }
    }
}
